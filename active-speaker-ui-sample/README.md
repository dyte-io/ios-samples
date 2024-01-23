<!-- PROJECT LOGO -->
<p align="center">
  <h2 align="center">Active Speaker UI Sample</h3>

  <p align="center">
    This sample showcases how you can build a UI to display only the active speaker while screenshare in a Webinar meeting with Dyte's iOS UI Kit!
    <br />
    <a href="https://docs.dyte.io"><strong>Explore the docs »</strong></a>
    <br />
  </p>
</p>

<!-- GETTING STARTED -->

## Getting Started

1. To run the sample app, start by cloning this repo:

    ```sh
    git clone https://github.com/dyte-io/ios-samples.git
    ```

2. Run `pod install` and Open the `active-speaker-ui-sample.xcworkspace` project in Xcode.

3. Paste the `authToken` of a participant with Webinar Preset on [line#26]() of the ViewController

4. Click the build/run button to run the app in an simulator/physical device

<!-- Implementation Overview -->

## Implementation Overview

This section provides a concise overview of how the whole UI is implemented in the sample code.

- [ViewController](#ViewController)
- [Set-up screen](#set-up-screen)
- [Webinar screen](#webinar-screen)
- [Chat Screen](#chat-screen)
- [Polls screen](#poll-screen)
- [Settings dialog](#settings-dialog)
- [Raise Hand button](#raise-hand-button)
- [Join stage confirmation dialog](#join-stage-confirmation-dialog)
- [Leave Webinar dialog](#leave-webinar-dialog)

#### ViewController
- The `ViewController` is implemented using APIs from the Dyte's iOS UI Kit and starts the flow from `viewWillLayoutSubviews()`.
- It implements the `AppFlowCoordinatorDelegate` protocol from the UI Kit to show the appropriate screen dynamically. The behaviour can be easily modified in the code if you want to have custom navigation.

#### Set-up screen
- The sample code utilises the pre-built `SetupViewController` from the UI Kit to display the Set-up screen, thus `return nil` is present in `showSetUpScreen()` for `AppFlowCoordinatorDelegate`

#### Webinar screen
- This is a custom Webinar screen implemented to display only the active speaker during screenshare. The landscape layout demonstrates how the UI components from Dyte's iOS UIKit can be combined with your custom UI elements
- The Stage section is a cutom view that shows active speaker, screenshares, and plugins
- The Vertical ControlBar uses the `DyteControlBar` and `DyteControlBarButton`. Also, the `DyteControlBarButton` is extended to display the unread count dot on the Chat and Polls toggle buttons.

#### Chat screen
- The sample code utilises the prebuilt `DyteChatFragment` from the UI Kit
- In portrait mode, it is displayed full screen, and in landscape mode, it appears beside the Stage section

#### Polls screen
- The sample code utilises the prebuilt `ShowPollsViewController` from the UI Kit
- In portrait mode, it is displayed full screen, and in landscape mode, it appears beside the Stage section

#### Settings dialog
- This is a custom dialog implemented using UI components from the UI Kit

#### Raise Hand button
- This is a custom `DyteControlBarButton` that calls the appropriate APIs from the Core SDK according to the permissions and `stageStatus` of the particiant.

#### Join stage confirmation dialog
- This is a custom dialog implemented using the UI components from the UI Kit
- Utilises `DyteParticipantTileView` to display video preview and `DyteButton` to let the participant toggle mic-camera before joining stage. It also call the `DyteStage.join()` API from Dyte's `DyteiOSCore` SDK

#### Leave Webinar dialog
- This is a custom dialog which utilises `DyteMobileClient.leaveRoom()` API from Dyte's Android-Core SDK
