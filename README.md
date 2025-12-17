# VPChat - Real-Time Messaging Application

A modern, full-stack real-time messaging application built with Flutter and ASP.NET Core, featuring WhatsApp-style message status indicators and seamless cross-platform communication.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![ASP.NET Core](https://img.shields.io/badge/ASP.NET_Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![SignalR](https://img.shields.io/badge/SignalR-000000?style=for-the-badge&logo=signalr&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Features

### Core Messaging
- **Real-time messaging** with instant delivery using SignalR
- **Message status indicators** (Sent ✓, Delivered ✓✓, Seen ✓✓)
- **Group chat support** with multiple participants
- **Typing indicators** to show when users are typing
- **Message timestamps** with relative time display

### User Experience
- **Cross-platform support** - iOS, Android, Web, Desktop
- **Offline support** with automatic reconnection
- **Push notifications** for new messages
- **File sharing** with upload progress
- **Voice messages** recording and playback
- **Emoji support** with picker integration

### Advanced Features
- **Network resilience** with automatic reconnection
- **Message pagination** for performance
- **Search functionality** within chats
- **User presence** indicators
- **Dark/Light theme** support
- **Responsive design** for all screen sizes

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Networking**: HTTP + SignalR Client
- **Database**: SQLite (local caching)
- **UI Components**: Material Design 3

### Backend (ASP.NET Core)
- **Framework**: ASP.NET Core 8.0
- **Real-time**: SignalR Core
- **Database**: Entity Framework Core + SQLite
- **Authentication**: JWT Bearer Tokens
- **API**: RESTful + WebSocket

### DevOps & Tools
- **Version Control**: Git
- **Package Management**: NuGet (Backend), Pub (Frontend)
- **IDE**: Visual Studio Code
- **Testing**: xUnit (Backend), Flutter Test (Frontend)

## 📋 Prerequisites

Before running this application, make sure you have the following installed:

### For Backend Development
- **.NET 8.0 SDK** or later
- **Visual Studio 2022** or **VS Code** with C# extensions
- **SQLite** (included with .NET)

### For Frontend Development
- **Flutter SDK** (3.x or later)
- **Dart SDK** (3.x or later)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### System Requirements
- **Operating System**: Windows 10+, macOS 12+, Linux (Ubuntu 18.04+)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 5GB free space

## 🚀 Installation & Setup

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/vpchat.git
   cd vpchat/vpchat_backend
   ```

2. **Restore dependencies**
   ```bash
   dotnet restore
   ```

3. **Run database migrations**
   ```bash
   dotnet ef database update
   ```

4. **Run the backend server**
   ```bash
   dotnet run --project VPChat.Server
   ```

The API will be available at `http://localhost:5014`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd ../vpchat_fronend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint** (optional)
   Update `lib/config/api_config.dart` if needed for your backend URL.

4. **Run the application**
   ```bash
   flutter run
   ```

### Mobile Development Setup

For mobile development, additional setup is required:

#### Android
- Install Android SDK and Android Studio
- Configure Android emulator or connect physical device
- Run: `flutter run` (Android will be auto-detected)

#### iOS (macOS only)
- Install Xcode
- Configure iOS Simulator
- Run: `flutter run` (iOS will be auto-detected)

## 📱 Usage

### Starting the Application

1. **Start the backend server** first:
   ```bash
   cd vpchat_backend
   dotnet run --project VPChat.Server
   ```

2. **Start the frontend application**:
   ```bash
   cd vpchat_fronend
   flutter run
   ```

### Key Features Usage

#### Creating a Chat
1. Tap the "+" button in the chat list
2. Select "New Chat" or "New Group"
3. Choose participants
4. Start messaging!

#### Message Status Indicators
- **✓ Single check**: Message sent
- **✓✓ Gray checks**: Message delivered
- **✓✓ Blue checks**: Message read

#### File Sharing
1. Tap the attachment icon in chat
2. Select file from gallery or file system
3. Monitor upload progress
4. Recipient receives download link

## 📚 API Documentation

### Authentication Endpoints

#### POST /api/auth/login
Authenticate user and receive JWT token.

**Request:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "username": "string",
    "email": "string"
  }
}
```

#### POST /api/auth/register
Register a new user account.

### Chat Endpoints

#### GET /api/chats
Get user's chat list.

#### GET /api/chats/{chatId}/messages
Get messages for a specific chat with pagination.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `pageSize` (optional): Messages per page (default: 50)

#### POST /api/chats/{chatId}/messages
Send a message to a chat.

**Request:**
```json
{
  "content": "Hello, World!",
  "messageType": "text"
}
```

### Real-time Events (SignalR)

#### Hubs
- **ChatHub**: Main chat communication hub

#### Client Methods
- `SendMessage(int chatId, string content)`
- `JoinChat(int chatId)`
- `LeaveChat(int chatId)`
- `SendTypingIndicator(int chatId, bool isTyping)`

#### Server Events
- `MessageReceived(Message message)`
- `UserTyping(int userId, bool isTyping)`
- `MessageStatusUpdate(int chatId, List<int> messageIds, int status)`

## 🏗️ Project Structure

```
vpchat/
├── vpchat_backend/                 # ASP.NET Core Backend
│   ├── VPChat.Core/               # Core business logic
│   ├── VPChat.Server/             # Web API & SignalR server
│   ├── VPChat.Shared/             # Shared DTOs and models
│   └── VPChat.Tests/              # Unit tests
├── vpchat_fronend/                # Flutter Frontend
│   ├── lib/
│   │   ├── config/               # Configuration files
│   │   ├── models/               # Data models
│   │   ├── providers/            # State management
│   │   ├── screens/              # UI screens
│   │   ├── services/             # API & external services
│   │   └── widgets/              # Reusable UI components
│   ├── android/                  # Android platform code
│   ├── ios/                      # iOS platform code
│   └── web/                      # Web platform code
└── README.md                     # This file
```

## 🧪 Testing

### Backend Testing
```bash
cd vpchat_backend
dotnet test
```

### Frontend Testing
```bash
cd vpchat_fronend
flutter test
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** and ensure tests pass
4. **Commit your changes**: `git commit -m 'Add some feature'`
5. **Push to the branch**: `git push origin feature/your-feature-name`
6. **Open a Pull Request**

### Development Guidelines

- Follow the existing code style
- Write tests for new features
- Update documentation as needed
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you have any questions or need help:

- **Issues**: [GitHub Issues](https://github.com/yourusername/vpchat/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/vpchat/discussions)
- **Email**: support@vpchat.com

## 🔄 Version History

### v1.0.0 (Current)
- Initial release with core messaging features
- Real-time communication with SignalR
- Cross-platform Flutter app
- Message status indicators
- File sharing support

---

**Built with ❤️ using Flutter and ASP.NET Core**