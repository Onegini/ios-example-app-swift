//
// Copyright (c) 2018 Onegini. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

protocol RegisterUserInteractorProtocol: AnyObject {
    func identityProviders() -> Array<ONGIdentityProvider>
    func startUserRegistration(identityProvider: ONGIdentityProvider?)
    func handleRedirectURL()
    func handleCreatedPin()
    func handleOTPCode()
    func handleQRCode(_ qrCode: String?)
}

class RegisterUserInteractor: NSObject {
    weak var registerUserPresenter: RegisterUserInteractorToPresenterProtocol?
    var registerUserEntity = RegisterUserEntity()

    fileprivate func mapErrorFromChallenge(_ challenge: ONGCreatePinChallenge) {
        if let error = challenge.error {
            registerUserEntity.pinError = ErrorMapper().mapError(error)
        } else {
            registerUserEntity.pinError = nil
        }
    }
}

extension RegisterUserInteractor: RegisterUserInteractorProtocol {
    func identityProviders() -> Array<ONGIdentityProvider> {
        let identityProviders = ONGUserClient.sharedInstance().identityProviders()
        return Array(identityProviders)
    }

    func startUserRegistration(identityProvider: ONGIdentityProvider? = nil) {
        ONGUserClient.sharedInstance().registerUser(with: identityProvider, scopes: ["read", "write"], delegate: self)
    }

    func handleRedirectURL() {
        guard let browserRegistrationChallenge = registerUserEntity.browserRegistrationChallenge else { return }
        if let url = registerUserEntity.redirectURL {
            browserRegistrationChallenge.sender.respond(with: url, challenge: browserRegistrationChallenge)
        } else {
            browserRegistrationChallenge.sender.cancel(browserRegistrationChallenge)
        }
    }

    func handleOTPCode() {
        guard let customRegistrationChallenge = registerUserEntity.customRegistrationChallenge else { return }
        if registerUserEntity.cancelled {
            registerUserEntity.cancelled = false
            customRegistrationChallenge.sender.cancel(customRegistrationChallenge)
        } else {
            customRegistrationChallenge.sender.respond(withData: registerUserEntity.responseCode, challenge: customRegistrationChallenge)
        }
    }

    func handleQRCode(_ qrCode: String?) {
        guard let customRegistrationChallenge = registerUserEntity.customRegistrationChallenge else { return }
        if let qrCode = qrCode {
            customRegistrationChallenge.sender.respond(withData: qrCode, challenge: customRegistrationChallenge)
        } else {
            customRegistrationChallenge.sender.cancel(customRegistrationChallenge)
        }
    }

    func handleCreatedPin() {
        guard let createPinChallenge = registerUserEntity.createPinChallenge else { return }
        if let pin = registerUserEntity.pin {
            createPinChallenge.sender.respond(withCreatedPin: pin, challenge: createPinChallenge)
        } else {
            createPinChallenge.sender.cancel(createPinChallenge)
        }
    }

    fileprivate func mapErrorMessageFromTwoWayOTPStatus(_ status: Int) {
        if status == 2000 {
            registerUserEntity.errorMessage = nil
        } else if status == 4002 {
            registerUserEntity.errorMessage = "This code is not initialized on portal."
        } else {
            registerUserEntity.errorMessage = "Provided code is incorrect."
        }
    }

    fileprivate func mapErrorMessageFromQRCodeStatus(_ status: Int) {
        if status == 2000 {
            registerUserEntity.errorMessage = nil
        } else {
            registerUserEntity.errorMessage = "QR code is not valid."
        }
    }

    fileprivate func mapErrorMessageFromStatus(_ status: Int, identityProviderIdentifier: String) {
        if identityProviderIdentifier == "2-way-otp-api" {
            mapErrorMessageFromTwoWayOTPStatus(status)
        } else if identityProviderIdentifier == "qr-code-api" {
            mapErrorMessageFromQRCodeStatus(status)
        }
    }
}

extension RegisterUserInteractor: ONGRegistrationDelegate {
    func userClient(_: ONGUserClient, didReceive challenge: ONGBrowserRegistrationChallenge) {
        registerUserEntity.browserRegistrationChallenge = challenge
        registerUserEntity.registrationUserURL = challenge.url
        registerUserPresenter?.presentBrowserUserRegistrationView(regiserUserEntity: registerUserEntity)
    }

    func userClient(_: ONGUserClient, didReceivePinRegistrationChallenge challenge: ONGCreatePinChallenge) {
        registerUserEntity.createPinChallenge = challenge
        registerUserEntity.pinLength = Int(challenge.pinLength)
        mapErrorFromChallenge(challenge)
        registerUserPresenter?.presentCreatePinView(registerUserEntity: registerUserEntity)
    }

    func userClient(_ userClient: ONGUserClient, didRegisterUser userProfile: ONGUserProfile, identityProvider: ONGIdentityProvider, info: ONGCustomInfo?) {
        registerUserPresenter?.presentDashboardView(authenticatedUserProfile: userProfile)
    }
    
    func userClient(_ userClient: ONGUserClient, didFailToRegisterWith identityProvider: ONGIdentityProvider, error: Error) {
        if error.code == ONGGenericError.actionCancelled.rawValue {
            registerUserPresenter?.registerUserActionCancelled()
        } else {
            let mappedError = ErrorMapper().mapError(error)
            registerUserPresenter?.registerUserActionFailed(mappedError)
        }
        registerUserEntity.errorMessage = nil
    }

    func userClient(_: ONGUserClient, didReceiveCustomRegistrationInitChallenge challenge: ONGCustomRegistrationChallenge) {
        if challenge.identityProvider.identifier == "2-way-otp-api" {
            challenge.sender.respond(withData: nil, challenge: challenge)
        }
    }

    func userClient(_: ONGUserClient, didReceiveCustomRegistrationFinish challenge: ONGCustomRegistrationChallenge) {
        registerUserEntity.customRegistrationChallenge = challenge
        if let info = challenge.info {
            registerUserEntity.challengeCode = info.data
            mapErrorMessageFromStatus(info.status, identityProviderIdentifier: challenge.identityProvider.identifier)
        }
        if challenge.identityProvider.identifier == "2-way-otp-api" {
            registerUserPresenter?.presentTwoWayOTPRegistrationView(regiserUserEntity: registerUserEntity)
        } else if challenge.identityProvider.identifier == "qr-code-api" {
            registerUserPresenter?.presentQRCodeRegistrationView(registerUserEntity: registerUserEntity)
        }
    }
}
