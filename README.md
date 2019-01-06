# PhoneX iOS application

PhoneX is uses PJSIP library (dependency/pjproject) which needs to be compiled for PhoneX to work.

We have our own patch set on top of the PJSIP. Only the unpatched PJSIP version is versioned
so we can easily update PJSIP from the upstream, compare changes. In order to make PhoneX work
 patches have to be applied on top of the PJSIP (with quilt). Patched files are not versioned,
 please do not commit them to the git repository.

## Dependencies

Install following dependencies (with brew / ports):

- quilt
- swig

## Building the project

- checkout repository the project repository
- `git submodule init`
- `git submodule update`
- `pod install` install CocoaPods https://guides.cocoapods.org/using/getting-started.html
- `cd ${PROJECT}/dependency/pjproject`
- - `make debug`
- - `make clean`
- `cd ${PROJECT}/dependency/zrtpcpp`
- - `sh _build.sh`

8. DEPRECATED: revert changes made by patches (quilt).

7. with XCode open the workspace
- opening only the project will ignore CocoaPods subprojects in build

