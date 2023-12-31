# installipa15
Browse installed IPA files from command line updated for iOS 15.  
Verified on iPhoneX palear1n iOS 15.6

All code copyright of the respective owners, and pulled from [autopear](https://github.com/autopear/ipainstaller) originally.  
Updates to work on iOS 15 done by me.   
Lot of options removed as covered by different tools, -i and -l being the most useful.

## Installation
- Grab the packaged .deb and push to device via scp.
- Install the .deb specifying the inst dir because of rootless JB.
```
$ dpkg -i com.bensh.installipa15_1.0_iphone-arm64.deb
```
- Find the binary, then run, or add to path
```
$ dpkg -L com.bensh.installipa15                        
/var/jb/usr/bin/installipa15

$ find / -name installipa15 -print 2>/dev/null
/private/preboot/XXXXXXXXXXXXXXXXXXXXXXXXXXX/jb-XXXXXX/procursus/var/root/installipa15
```

## Usage
```
iPhone:~ root# installipa15 
Usage: installipa15 [OPTION]...
       installipa15 -i [APP_ID]...
       installipa15 -l
       
Options:
    -a  Show tool about information.
    -h  Display this usage information.
    -i  Display information of installed application(s).
    -l  List identifiers of all installed App Store applications.

iPhone:~ root# installipa15 -l
com.bt.btfon
com.test.myapp
com.MX799XR3LS.com.rileytestut.AltStore

iPhone:~ root# installipa15 -i com.test.myapp
Identifier: com.test.myapp
Version: 1
Short Version: 1.0
Name: My App
Display Name: My App
Bundle: /private/var/containers/Bundle/Application/92ED70CF-09D8-4529-BCDB-4ED4510F76B7
Application: /private/var/containers/Bundle/Application/92ED70CF-09D8-4529-BCDB-4ED4510F76B7/My App.app
Data: /private/var/mobile/Containers/Data/Application/CBDF993D-7908-40D3-BE42-F553AEDC6FB7
```

## Build
Clone the git, and run make from the parent dir - requires [theos](https://theos.dev/docs/installation-macos) and updated sdks.
```
installipa15$ make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
==> Notice: Build may be slow as Theos isn’t using all available CPU cores on this computer. Consider upgrading GNU Make: https://theos.dev/docs/parallel-building
> Making all for tool installipa15…
==> Compiling UIDevice-Capabilities/UIDevice-Capabilities.m (arm64)…
==> Compiling main.m (arm64)…
==> Linking tool installipa15 (arm64)…
==> Generating debug symbols for installipa15…
==> Stripping installipa15 (arm64)…
==> Merging tool installipa15…
==> Signing installipa15…
> Making stage for tool installipa15…
dm.pl: building package `com.bensh.installipa15:iphoneos-arm64' in `./packages/com.bensh.installipa15_1.0_iphoneos-arm64.deb'
```
