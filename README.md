# 🐾 Pet Adoption Kerala

A modern Flutter-based mobile application that connects pet owners with adopters, making pet adoption simple, fast, and accessible.

---

## 🚀 Features

### 🐶 Pet Listings

* Add pets with images, breed, and location
* Browse pets available nearby
* View detailed pet profiles

### 💬 Chat System

* Real-time messaging between users
* Pet-specific conversations
* Clean WhatsApp-style UI
* Unread message indicator

### ❤️ Adoption Requests

* Send adoption requests to pet owners
* Approve or reject requests
* Track request status

### 👤 User Profile

* View user details
* Manage personal pet listings
* Delete pets (auto removes chats)

### 📍 Location-Based Discovery

* Find pets near your location using GPS

---

## 🛠 Tech Stack

* **Flutter** (UI Framework)
* **GetX** (State Management & Navigation)
* **Firebase Authentication**
* **Cloud Firestore** (Database)
* **Cloudinary** (Image Upload)
* **Geolocator** (Location Services)

---

## 📱 Screens

* Splash Screen
* Login / Authentication
* Home (Pet Listings)
* Pet Details
* Chat (Messages)
* Favorites
* My Listings
* Adoption Requests
* Profile

---

## 📂 Project Structure

```
lib/
│
├── models/
│   ├── auth/
│   ├── chat/
│   ├── home/
│   ├── pet_detail/
│   ├── profile/
│
├── widgets/
├── utils/
├── main.dart
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the repository

```
git clone https://github.com/your-username/pet-adoption-kerala.git
cd pet-adoption-kerala
```

---

### 2️⃣ Install dependencies

```
flutter pub get
```

---

### 3️⃣ Configure Firebase

* Create a Firebase project
* Add Android app
* Download `google-services.json`
* Place it in:

```
android/app/google-services.json
```

---

### 4️⃣ Run the app

```
flutter run
```

---

## 📦 Build APK

```
flutter build apk --release
```

---

## 🔐 Firebase Collections

### pets

```
name
breed
ownerId
location
lat
lng
mediaUrl
createdAt
```

### chats

```
users[]
petId
lastMessage
updatedAt
unreadCount{}
```

### messages (subcollection)

```
senderId
text
createdAt
```

### adoption_requests

```
petId
ownerId
requesterId
status (pending/approved/rejected)
createdAt
```

---

## 💡 Future Improvements

* Push Notifications (FCM)
* User Profiles with images
* Online/Offline status
* Image chat support
* Admin dashboard

---

## 👨‍💻 Author

**Agesh K S**
Flutter Developer

---

## 📄 License

This project is for educational and commercial use.
