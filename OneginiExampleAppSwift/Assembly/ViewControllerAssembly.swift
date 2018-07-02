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
import Swinject

class ViewControllerAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(StartupViewController.self) { _ in StartupViewController() }
        container.register(LoginViewController.self) { _ in LoginViewController() }
        container.register(RegisterUserViewController.self) { r in
            let registerUserViewController = RegisterUserViewController()
            registerUserViewController.registerUserViewToPresenterProtocol = r.resolve(RegisterUserPresenterProtocol.self)
            return registerUserViewController
        }
        
        container.register(WelcomeViewController.self) { (r: Resolver, welcomePresenterProtocol: WelcomePresenter) in
            let welcomeViewController = WelcomeViewController()
            welcomeViewController.welcomePresenterProtocol = welcomePresenterProtocol
            
            return welcomeViewController
        }
    }

}
