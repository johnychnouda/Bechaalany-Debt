#!/bin/bash

# Java Installation Helper for macOS

echo "=========================================="
echo "Java Installation Helper"
echo "=========================================="
echo ""

# Check if Java is already installed
if command -v java &> /dev/null; then
    echo "✅ Java is already installed!"
    java -version
    echo ""
    if command -v keytool &> /dev/null; then
        echo "✅ keytool is available!"
        echo ""
        echo "You can now run: ./setup_android_signing.sh"
        exit 0
    fi
fi

echo "Java is not installed. Let's install it!"
echo ""

# Check if Homebrew is installed
if command -v brew &> /dev/null; then
    echo "✅ Homebrew is installed. Using Homebrew to install Java..."
    echo ""
    echo "Installing OpenJDK 17..."
    brew install openjdk@17
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "Setting up Java..."
        sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || \
        sudo ln -sfn /usr/local/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null
        
        # Add to PATH
        if [[ "$SHELL" == *"zsh"* ]]; then
            SHELL_RC="$HOME/.zshrc"
        else
            SHELL_RC="$HOME/.bash_profile"
        fi
        
        if ! grep -q "openjdk@17" "$SHELL_RC" 2>/dev/null; then
            echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> "$SHELL_RC" 2>/dev/null || \
            echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> "$SHELL_RC" 2>/dev/null
        fi
        
        export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" 2>/dev/null || \
        export PATH="/usr/local/opt/openjdk@17/bin:$PATH" 2>/dev/null
        
        echo ""
        echo "✅ Java installed successfully!"
        java -version
        echo ""
        echo "You can now run: ./setup_android_signing.sh"
    else
        echo ""
        echo "❌ Installation failed. Please install Java manually."
        echo "See INSTALL_JAVA.md for instructions."
    fi
else
    echo "Homebrew is not installed."
    echo ""
    echo "You have two options:"
    echo ""
    echo "Option 1: Install Homebrew first (recommended for developers)"
    echo "  Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "  Then run this script again."
    echo ""
    echo "Option 2: Download Java directly (easier)"
    echo "  1. Visit: https://adoptium.net/temurin/releases/"
    echo "  2. Select: Version 17, macOS, ARM64 (M1/M2) or x64 (Intel)"
    echo "  3. Download and install the .pkg file"
    echo "  4. Then run: ./setup_android_signing.sh"
    echo ""
    echo "For detailed instructions, see: INSTALL_JAVA.md"
    echo ""
    
    # Try to open the download page
    read -p "Would you like to open the Java download page in your browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "https://adoptium.net/temurin/releases/?version=17"
    fi
fi
