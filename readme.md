# TideTimes iOS App

A beautiful and user-friendly iOS application that provides accurate tide information for any location worldwide. Built with SwiftUI, the app shows tide heights and times in an elegant graph format with detailed 24-hour forecasts.

## Features

- 🌊 Real-time tide data from WorldTides API
- 📍 Location search with auto-suggestions
- 💾 Remembers your last viewed location
- 📈 Interactive tide height graph
- 🕒 24-hour tide forecast
- 🔄 High and low tide indicators
- 📱 Native iOS design following Apple's guidelines

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- WorldTides API key

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/TideTimes.git
```

2. Set up your API key:
   - Copy the configuration template:
   ```bash
   cp TideTimes/Config.swift.template TideTimes/Config.swift
   ```
   - Edit `Config.swift` and replace `YOUR_API_KEY` with your [WorldTides API key](https://www.worldtides.info/api)

3. Open the project in Xcode:
```bash
open TideTimes.xcodeproj
```

4. Build and run the project (⌘R)

## Usage

1. **Search Location**
   - Tap the search field at the top
   - Enter a location name
   - Select from the suggested locations

2. **View Tide Data**
   - See current tide height on the graph
   - View upcoming high and low tides
   - Check the 24-hour forecast table

3. **Saved Location**
   - Your last viewed location is automatically saved
   - It will be restored when you reopen the app

## Architecture

The app is built using:
- SwiftUI for the user interface
- Combine for reactive programming
- CoreLocation for location services
- WorldTides API for tide data

Key components:
- `NetworkManager`: Handles API communication
- `LocationManager`: Manages location services
- `SettingsManager`: Handles user preferences
- `GraphView`: Custom tide visualization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Troubleshooting

Common issues and solutions:

1. **API Key Issues**
   - Verify your API key in `Config.swift`
   - Check API quota limits
   - Ensure internet connectivity

2. **Location Services**
   - Enable Location Services in iOS Settings
   - Grant necessary permissions to the app
   - Check for restricted locations

## License

This project is licensed under the MIT License - see [LICENSE.md](LICENSE.md) for details.

## Acknowledgments

- [WorldTides API](https://www.worldtides.info/api) for tide data
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the UI framework
- [Apple Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Author

Peter Chua-Lao

## Support

If you find this project helpful, please give it a ⭐️!

For support, please create an issue in the repository.