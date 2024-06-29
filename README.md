# VisiCalc 6502 Recreation

Welcome to the VisiCalc 6502 Recreation project! This repository aims to recreate the original source code for VisiCalc, the pioneering spreadsheet software first released in 1979. This project is a collaborative effort involving some of the original creators of VisiCalc and is dedicated to preserving and restoring this important piece of computing history.

## Table of Contents

- [Project Overview](#project-overview)
- [Background](#background)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Project Overview

VisiCalc was the first electronic spreadsheet program, transforming the way businesses and individuals handled data and calculations. It was originally developed for the Apple II computer using the 6502 assembly language. The original source code, unfortunately, has been lost to time. This project aims to recreate the source code from scratch, staying true to the original functionality and performance.

## Background

VisiCalc, short for "Visible Calculator," was created by Dan Bricklin and Bob Frankston. It allowed users to perform complex calculations on a grid of cells, making it an invaluable tool for accountants, business professionals, and academics. VisiCalc laid the foundation for future spreadsheet applications like Lotus 1-2-3 and Microsoft Excel.

## Getting Started

### Prerequisites

To work with this project, you will need:

- An assembler for the 6502 microprocessor (e.g., [CA65](https://cc65.github.io/doc/ca65.html))
- An Apple II emulator (e.g., [AppleWin](https://applewin.berlios.de/)) or real Apple II hardware
- Git for version control

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/davidrimshnick/visicalc_da.git
    ```
2. Navigate to the project directory:
    ```sh
    cd visicalc_da
    ```
3. Assemble the source code using your preferred 6502 assembler:
    ```sh
    ca65 visicalc-6502.asm -o visicalc.o
    ld65 -t apple2 -o visicalc.bin visicalc.o
    ```

## Usage

Load the assembled binary (`visicalc.bin`) into your Apple II emulator or transfer it to your Apple II hardware. Follow the emulator's or hardware's instructions for running the binary.

## Contributing

We welcome contributions from the community! If you would like to contribute:

1. Fork the repository.
2. Create a new branch:
    ```sh
    git checkout -b feature/your-feature-name
    ```
3. Commit your changes:
    ```sh
    git commit -m 'Add some feature'
    ```
4. Push to the branch:
    ```sh
    git push origin feature/your-feature-name
    ```
5. Open a pull request.

Please ensure your code adheres to the project's coding standards and includes appropriate comments and documentation.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Special thanks to Dan Bricklin and Bob Frankston for their groundbreaking work on the original VisiCalc. We also thank the computing community for their ongoing support and contributions to preserving software history.

---

We hope this project not only brings back a vital piece of software history but also inspires new generations to understand and appreciate the evolution of computing technology. Happy coding!
