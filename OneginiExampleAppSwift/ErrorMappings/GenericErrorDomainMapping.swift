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

class GenericErrorDomainMapping {
    
    func mapError(_ error: Error) -> AppError {
        switch error.code {
        case ONGGenericError.networkConnectivityFailure.rawValue, ONGGenericError.serverNotReachable.rawValue:
            return AppError(title: "Connection error", errorDescription:"Failed to connect to the server.")
        case ONGGenericError.userDeregistered.rawValue:
            return AppError(title: "User error", errorDescription: "The user account is deregistered from the device.", recoverySuggestion: "Try register your user again.")
        case ONGGenericError.deviceDeregistered.rawValue:
            return AppError(title: "Device error", errorDescription: "All users got disconnected from the device.", recoverySuggestion: "Try register your user again.")
        case ONGGenericError.outdatedOS.rawValue:
            return AppError(title: "OS error", errorDescription: "Your os version is outdated.", recoverySuggestion: "Try update your os version.")
        default:
            return AppError(errorDescription: "Something went wrong.")
        }
    }
    
}
