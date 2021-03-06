<img src="gameAssets/thumbnail.svg" width="1080">

## Building [![Build Status](https://travis-ci.com/Flying-Toast/wiziz.svg?branch=master)](https://travis-ci.com/Flying-Toast/wiziz)

Wiziz is written in D. In order to build it, you need dmd (the D compiler) and dub (the D package/build manager). Both of these can be downloaded from [dlang.org](https://dlang.org).

<span id="linuxBuildInstructions"></span>
### Linux + macOS
1. Clone the git repo: `git clone https://github.com/Flying-Toast/wiziz`.
2. `cd wiziz`.
3. Compile and run with `dub run` (this will also automatically fetch dependencies).
4. Navigate to ht<span></span>tp://localhost:8080 in a web browser to test/preview changes.

### Windows
Wiziz is not tested natively on Windows, but if you have Windows 10, you can run it using the Windows Subsystem for Linux:

#### Setting up Windows Subsystem for Linux
1. Open Control Panel -> Programs -> Turn Windows features on or off -> select "Windows Subsystem for Linux" and click OK. (Reboot if prompted).
2. Install the ['Ubuntu' Windows app](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q).
3. Open the 'Ubuntu' app from the start menu.
4. Enter a username and password as prompted.
5. Close Ubuntu.
6. Open PowerShell.
7. Run `bash`.
8. Run `curl https://raw.githubusercontent.com/Flying-Toast/wiziz/master/wslSetup.sh | bash -s` (this will take a while).
9. Close PowerShell.
10. That's all for the setup! (You only have to do it once).

#### Build Instructions
1. Open PowerShell.
2. Run `bash`.
3. Follow the [build instructions for Linux](#linuxBuildInstructions).
