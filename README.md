# SHISHRA - Premium Jewelry Ecommerce App

A complete, GIVA-inspired ecommerce application built with Flutter, featuring a modern UI design and full ecommerce functionality for jewelry shopping.

## ✨ Features

### 🏠 **Home & Navigation**
- **Modern Bottom Navigation** with 4 main sections
- **Search Functionality** with real-time filtering
- **Category Filtering** (Necklaces, Earrings, Rings, Bracelets, etc.)
- **Product Grid Display** with responsive design
- **Product Count Display** showing filtered results

### 🛍️ **Product Management**
- **12+ Premium Jewelry Products** with high-quality images
- **Product Categories**: Necklaces, Earrings, Rings, Bracelets, Anklets, Nose Pins, Toe Rings, Waist Chains, Mangalsutra
- **Product Details**: Name, price, description, category, rating, reviews, stock status
- **Interactive Product Cards** with wishlist and quick add-to-cart buttons

### ❤️ **Wishlist System**
- **Add/Remove Products** to/from wishlist
- **Wishlist Counter** in navigation
- **Wishlist Page** with product grid view
- **Clear All Wishlist** functionality
- **Persistent Wishlist** across app sessions

### 🛒 **Shopping Cart**
- **Add Products** to cart with quantity management
- **Cart Counter** in navigation
- **Quantity Controls** (increase/decrease/remove)
- **Cart Total Calculation** with shipping
- **Cart Page** with product list and checkout button

### 💳 **Checkout Process**
- **Complete Checkout Flow** with form validation
- **Delivery Address Form** (name, phone, address, city, pincode)
- **Payment Method Selection** (Cash on Delivery, Online Payment)
- **Order Summary** with product details and totals
- **Order Processing** with loading states

### 📱 **Order Management**
- **Order Confirmation Page** with success message
- **Order Details** (Order ID, Date, Expected Delivery)
- **Next Steps Information** for customers
- **Continue Shopping** and **Track Order** options

### 🎨 **Theme & Customization**
- **Light & Dark Theme** support
- **GIVA-Inspired Design** with premium aesthetics
- **Custom Color Scheme** with black and white primary colors
- **Material Design 3** implementation
- **Responsive Typography** and spacing

### ⚙️ **Settings & Preferences**
- **Theme Toggle** (Light/Dark mode)
- **Account Management** (Profile, Addresses)
- **Support Options** (Help Center, Contact Us)
- **App Information** and version details

### 🔐 **SECRET ADMIN ACCESS** 🔐
**The unique feature you requested!**

#### How to Access Admin Mode:
1. Go to the Login screen
2. **Tap the app logo 7 times within 4 seconds**
3. A secret Admin Access modal will appear
4. Enter the admin password: `admin123` (default)
5. Successfully authenticate to enter Admin Mode

#### Admin Dashboard Features:
- **Order Management** - View, filter, and update order statuses
- **Product Management** - Add, edit, delete products with image upload
- **User Management** - View customer data and order history
- **Settings & Configuration** - Maintenance mode, notifications, store settings
- **Analytics Overview** - Sales summary and key metrics
- **Security** - Change admin password, view access logs

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.2.0)
- Dart SDK (>=3.2.0)
- iOS Simulator or Android Emulator
- VS Code or Android Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd shishra
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building the App

- **Web Build**
  ```bash
  flutter build web
  ```

- **iOS Build**
  ```bash
  flutter build ios --no-codesign
  ```

- **Android Build**
  ```bash
  flutter build apk
  ```

## 🏗️ Architecture

### **State Management**
- **Provider Pattern** for app-wide state management
- **ChangeNotifier** for reactive UI updates
- **Centralized AppState** managing all app data

### **File Structure**
```
lib/
├── main.dart                 # App entry point
├── globals/
│   ├── app_state.dart       # Main app state management
│   └── themes.dart          # Light and dark themes
├── pages/
│   ├── main_navigation.dart # Bottom navigation wrapper
│   ├── home_page.dart       # Home page with search and filters
│   ├── wishlist_page.dart   # Wishlist management
│   ├── cart_page.dart       # Shopping cart
│   ├── checkout_page.dart   # Checkout process
│   ├── order_confirmation_page.dart # Order success
│   ├── product_detail_page.dart # Product details
│   └── settings_page.dart   # App settings and preferences
├── components/
│   ├── product_card.dart    # Product display card
│   └── cart_item_widget.dart # Cart item display
├── product.dart             # Product data model
└── cart_item.dart           # Cart item data model
```

### **Key Components**

- **AppState**: Central state management for products, cart, wishlist, search, and themes
- **Product Model**: Data structure for jewelry products with all necessary attributes
- **CartItem Model**: Shopping cart item with quantity and total price calculation
- **Theme System**: Comprehensive theming with Material Design 3 support

## 🎯 Key Features Implementation

### **Search & Filtering**
- Real-time search across product names, descriptions, and categories
- Category-based filtering with chip selection
- Dynamic product count display
- Empty state handling with clear filters option

### **Wishlist System**
- Heart icon toggle on product cards
- Wishlist counter in navigation
- Dedicated wishlist page with product grid
- Clear all functionality

### **Shopping Cart**
- Add to cart from product cards and detail pages
- Quantity management with +/- controls
- Remove items functionality
- Cart total calculation
- Empty cart state handling

### **Checkout Process**
- Multi-step checkout form with validation
- Address and contact information collection
- Payment method selection
- Order summary display
- Processing states and success confirmation

## 🎨 Design Features

### **Visual Design**
- **Premium Aesthetics** inspired by GIVA jewelry store
- **Clean Typography** with proper hierarchy
- **Consistent Spacing** and padding throughout
- **Subtle Shadows** and borders for depth
- **Responsive Grid Layout** for products

### **Color Scheme**
- **Primary**: Black (#1A1A1A) for premium feel
- **Secondary**: White for clean backgrounds
- **Accent**: Red for wishlist indicators
- **Supporting**: Various grey shades for text and borders

### **Interactive Elements**
- **Hover Effects** on buttons and cards
- **Loading States** for async operations
- **Success/Error Messages** with snackbars
- **Smooth Transitions** between pages

## 📱 Platform Support

- ✅ **iOS** - Full native support
- ✅ **Android** - Full native support  
- ✅ **Web** - Responsive web application
- ✅ **macOS** - Desktop application
- ✅ **Windows** - Desktop application
- ✅ **Linux** - Desktop application

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  nowa_runtime: ^0.0.44
  flutter_html: ^3.0.0-beta.2
  flutter_svg: ^2.0.7
  provider: ^6.1.1
  shared_preferences: ^2.2.3
  dio: ^5.5.0+1
  collection: ^1.19.1
```

## 🚀 Future Enhancements

- [ ] **User Authentication** and account management
- [ ] **Payment Gateway Integration** (Stripe, Razorpay)
- [ ] **Order Tracking** system
- [ ] **Push Notifications** for order updates
- [ ] **Product Reviews** and ratings system
- [ ] **Size Guide** and fitting recommendations
- [ ] **AR Try-On** for jewelry visualization
- [ ] **Multi-language Support** (English, Hindi)
- [ ] **Offline Mode** with local storage
- [ ] **Analytics** and user behavior tracking

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions, please contact the development team or create an issue in the repository.

---

**SHISHRA** - Where Elegance Meets Technology ✨
