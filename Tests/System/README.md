# System Level Tests

> [!NOTE]
> This directory houses various *system-level, integration* tests that are used to verify the functionality of the
> system being used by the user. These tests are designed to test the system as a whole, rather than individual components
> specific to this project.

## Contents

- [Overview](#overview)
- [Planned Additions](#planned-additions)
- [Usage](#usage)

## Overview

The following is a list of the various system-level tests that are included in this directory:

- [Docker Tests](./Docker.Tests.ps1): Tests that verify the proper installation, setup, and configuration of Docker
  and related tools.

- [Explorer Tests](./Explorer.Tests.ps1): Tests that verify the configuration of the native Windows File Explorer
  program and its associated settings and options.

- [Git Tests](./Git.Tests.ps1): Tests that verify the configuration of the Git version control system and its associated
  settings and options.

- [Installed Software Tests](./InstalledApps.Tests.ps1): Tests that verify the installation and configuration of
  various software packages and tools that are commonly used in the development process.

- [Network Tests](./Network.Tests.ps1): Tests that verify the configuration of the network settings and options on the
  system.

- [PowerShell Tests](./PowerShell.Tests.ps1): Tests that verify the configuration of the PowerShell environment and

- [Installed Modules Tests](./InstalledModules.Tests.ps1): Tests that verify the installation and configuration of
  various PowerShell modules that are commonly used in the development process.

- [Windows Terminal Tests](./Terminal.Tests.ps1): Tests that verify the configuration of the Windows Terminal program

- [Visual Studio Code Tests](./VSCode.Tests.ps1): Tests that verify the configuration of the Visual Studio Code editor
  and its associated settings and options.

- [Windows Subsystem for Linux (WSL) Tests](./WSL.Tests.ps1): Tests that verify the installation and configuration of

- [SSH Tests](./SSH.Tests.ps1): Tests that verify the configuration of the SSH client and server on the system.

- [Windows Terminal Tests](./WindowsTerminal.Tests.ps1): Tests that verify the configuration of the Windows Terminal program
  and its associated settings and options.

- [Winget Tests](./Winget.Tests.ps1): Tests that verify the installation and configuration of the Windows Package Manager
  (winget) and its associated settings and options.

### Planned Additions

- [Windows Update Tests](./WindowsUpdate.Tests.ps1): Tests that verify the configuration of the Windows Update service
  and its associated settings and options.

- [Windows Defender Tests](./WindowsDefender.Tests.ps1): Tests that verify the configuration of the Windows Defender

- [Windows Firewall Tests](./WindowsFirewall.Tests.ps1): Tests that verify the configuration of the Windows Firewall
  and its associated settings and options.

- [Windows Security Tests](./WindowsSecurity.Tests.ps1): Tests that verify the configuration of the Windows Security

- [Windows Settings Tests](./WindowsSettings.Tests.ps1): Tests that verify the configuration of various Windows settings
  and options on the system.

- [Windows Services Tests](./WindowsServices.Tests.ps1): Tests that verify the configuration of various Windows services

## Usage

To run the system-level tests, execute the following command from the root of the repository:

```powershell
Invoke-Pester -Path .\Tests\Integration\System
```

This will run all of the system-level tests in the repository and display the results in the console.

## Results

The results of the system-level tests will be displayed in the console, showing the status of each test and any
failures that occurred. If any tests fail, the output will indicate which tests failed and provide additional information
about the failure.

If all tests pass, the output will indicate that all tests passed successfully.

In the future, the option to generate a report of the test results will be added to the system-level tests, allowing
users to view the results in a more detailed format.

## Additional Information

For more information on the system-level tests in this directory, please refer to the individual test files and the
documentation provided in each test file. If you have any questions or need further assistance, please feel free to
reach out to the project maintainers for help.

## Conclusion

The system-level tests in this directory are designed to verify the configuration and functionality of the system as a
whole, ensuring that all components are working correctly and that the system is properly set up for development and
use. By running these tests regularly, users can ensure that their system is in good working order and that any issues
or problems are identified and addressed promptly.
