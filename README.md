# ModuleRoute

![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

ModuleRoute is a modular routing framework designed to simplify navigation within your Swift applications. Leveraging the Service Locator pattern, ModuleRoute enables clean, scalable, and maintainable routing architecture for iOS projects.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Setup](#setup)
  - [Registering Modules and Routes](#registering-modules-and-routes)
  - [Navigating Between Modules](#navigating-between-modules)
  - [Deep Linking](#deep-linking)
  - [Middleware and Interceptors](#middleware-and-interceptors)
- [Contribution](#contribution)
- [License](#license)

## Features

- **Modular Architecture**: Organize your app into distinct modules with clear separation of concerns.
- **Service Locator Integration**: Efficient dependency management using Service Locator.
- **Middleware Support**: Process routes through customizable middleware.
- **Interceptors**: Intercept and handle routes based on custom logic.
- **Deep Linking**: Handle URL schemes and universal links seamlessly.
- **Flexible Navigation**: Support for various navigation types including push, present, modal, replace, and custom transitions.
- **Logging**: Built-in logging for route processing.

## Installation

ModuleRoute is distributed via Swift Package Manager (SPM).

### Swift Package Manager

1. Open your project in Xcode.
2. Go to `File` > `Add Packages...`.
3. Enter the ModuleRoute repository URL:
   ```
   https://github.com/GIKICoder/ModuleRoute
   ```
4. Choose the version you want to install and add the package to your project.

## Usage

### Setup

First, initialize the `ServiceLocator` and `MRNavigator` in your AppDelegate or SceneDelegate.

```swift
import ModuleRoute

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let serviceLocator = ServiceLocator()
    var navigator: MRNavigator!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        navigator = MRNavigator(serviceLocator: serviceLocator)

        // Register middleware
        navigator.addMiddleware(LoggingMiddleware())

        // Register modules and routes
        registerModules()

        return true
    }

    private func registerModules() {
        serviceLocator.register(MyModule.self, routes: [MyRoute.self]) {
            MyModule()
        }
    }
}
```

### Registering Modules and Routes

Create modules conforming to `MRModule` and define their supported routes.

```swift
import ModuleRoute

struct MyRoute: MRRoute {
    static var name: String { "myRoute" }
    var params: [String : Any] = [:]
    var callback: ((Any?) -> Void)? = nil
}

class MyModule: MRModule {
    static var supportedRoutes: [MRRoute.Type] = [MyRoute.self]

    func handle(route: MRRoute) -> RouteResult {
        switch route {
        case is MyRoute:
            let viewController = MyViewController()
            return .navigator(viewController)
        default:
            return .none
        }
    }
}
```

### Navigating Between Modules

Use `MRNavigator` to navigate to a specific route.

```swift
let route = MyRoute(params: ["key": "value"])
navigator.navigate(to: route, from: currentViewController, navigationType: .push, animated: true)
```

### Deep Linking

Register deep link handlers to handle incoming URLs.

```swift
navigator.registerDeepLinkHandler(scheme: "myapp") { url in
    guard let route = MRRoute.from(url: url) else { return nil }
    return route
}

// Handle incoming URL
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return navigator.handleDeepLink(url)
}
```

### Middleware and Interceptors

Customize route processing with middleware and interceptors.

```swift
// Middleware example
class AuthenticationMiddleware: MRMiddleware {
    func process(route: MRRoute, navigator: MRNavigator, next: @escaping (MRRoute) -> RouteResult) -> RouteResult {
        if !isAuthenticated {
            // Handle unauthorized access
            return .handler {
                // Show login screen or alert
            }
        }
        return next(route)
    }
}

// Interceptor example
class LoggingInterceptor: MRInterceptor {
    func shouldIntercept(route: MRRoute) -> Bool {
        // Define when to intercept
        return true
    }

    func handleInterception(route: MRRoute) -> RouteResult {
        // Handle the interception
        print("Route \(type(of: route)) intercepted")
        return .none
    }
}

// Adding Middleware and Interceptors
navigator.addMiddleware(AuthenticationMiddleware())
navigator.addInterceptor(LoggingInterceptor())
```

## Contribution

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/YourFeature`.
3. Commit your changes: `git commit -m 'Add some feature'`.
4. Push to the branch: `git push origin feature/YourFeature`.
5. Open a pull request.

Please ensure your code follows the project's coding standards and includes appropriate tests.

## License

ModuleRoute is released under the [MIT License](LICENSE).

---

Feel free to reach out or open an issue if you have any questions or need assistance.

