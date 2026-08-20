import QtQuick

// Text with the shared font + default foreground colour already applied.
// Override color / font.pixelSize / font.bold per use as needed.
Text {
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: 13
}
