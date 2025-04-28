<div align="center">
    <img src="/AppIcon.png" alt="App Icon" width="100" height="100">
    <h1>Friend（小友）</h1>
    <img src="/assets/AppEN.png" alt="App Screenshot" width="300">
</div>

## About the App (关于 APP)

Friend is a technical demo that showcases how system-based assistants can be integrated with LLMs to provide greater flexibility and functionality. It is especially useful for people with disabilities who may not be able to use traditional input methods. The app works by calling OpenAI APIs and providing access to tools that can perform actions on the device, such as retrieving the current time. This allows the LLM to complete tasks that would otherwise require direct user input.

小友是一个技术演示，展示了如何将系统级助手与大型语言模型（LLM）集成，以提供更高的灵活性和功能性。它对无法使用传统输入方式的残障人士尤其有帮助。该应用通过调用 OpenAI 接口，并向 LLM 提供访问设备工具的权限，例如获取当前时间。这样，LLM 就能够执行通常需要用户输入才能完成的任务。

## Features (功能)

- **Voice Input**: Users can interact with the app using voice commands, making it accessible for those with mobility impairments.
- **System Time & Date**: The LLM can access the system time and date.
- **Dark Mode**: The LLM can toggle dark mode on and off.
- **Weather Information**: The LLM can retrieve current weather information.
- **Geocoding**: The LLM can convert addresses into geographic coordinates.
- **Current Location**: The LLM can access the user's current location.
- **System Volume**: The LLM can adjust the system volume.

- **语音输入：**用户可以通过语音指令与应用交互，使行动不便的用户也能轻松使用。
- **系统时间与日期：**LLM 可以访问系统的时间和日期。
- **深色模式：**LLM 可以切换深色模式的开启与关闭。
- **天气信息：**LLM 可以获取当前的天气信息。
- **地理编码：**LLM 可以将地址转换为地理坐标。
- **当前位置：**LLM 可以访问用户的当前位置。
- **系统音量：**LLM 可以调整系统音量。

## Development (开发)

This app is built using SwiftUI and requires [`swift-bundler`](https://github.com/stackotter/swift-bundler) to be installed.

本应用基于 SwiftUI 开发，需要先安装 [`swift-bundler`](https://github.com/stackotter/swift-bundler)。

### Install swift-bundler (安装 swift-bundler)

```bash
mint install stackotter/swift-bundler@main
```

### Run the app (运行应用)

```bash
swift bundler run
```

## License (许可)

This project is licensed under the ISC License.
See the [LICENSE.md](LICENSE.md) file for details.

本项目基于 ISC 许可证。
详情请参见 [LICENSE.md](LICENSE.md) 文件。
