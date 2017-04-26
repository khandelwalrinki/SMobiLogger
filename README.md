SMobiLogger
===========

Provide logs from iOS device

Some of the major features of SMobilogger
- You can add logs with its type (i.e Information, Error, warning etc)
- You can set date value to delete old logs (to keep your logs smaller) ex. delete logs before 5 days
- Email client will be open by calling sendEmailLogs: method from your controller
- Your device and application information will be attached as a header
- In debug mode line number, method name and class name also logged for easy debugging

Installation steps:
- Drag SMobilloger directory in your project
- Download latest Realm & add follow instruction.

*Download the latest release of Realm and extract the zip.
Go to your Xcode project’s “General” settings. Drag Realm.framework from the ios/dynamic/, osx/, tvos/ or watchos/ directory to the “Embedded Binaries” section. Make sure Copy items if needed is selected (except if using Realm on multiple platforms in your project) and click Finish.*
