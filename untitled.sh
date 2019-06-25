#!/bin/bash
#该脚本仅适用于cocoapods生成的framework静态库
frameworkName='OggAudioPlayer'
#修改
oldversion='0.1.0'
#修改
version='0.1.0'
message='ogg格式音乐播放器'

pod lib lint ${frameworkName}.podspec  --no-clean --verbose --allow-warnings 
#代码提交到服务器
git add .
git commit -a -m${version}${message}
git tag -a $version -m${message}
git push origin ${version}
git push -u origin master 
#修改version
sed -i '' "s/${oldversion}/${version}/g" ${frameworkName}.podspec


#发布pod使用
##########################################################################
pod spec lint --allow-warnings
#发布到cocoapods库
pod trunk push ${frameworkName}.podspec --allow-warnings

#!!!!!The spec did not pass validation, due to 902 warnings!!!!!!!!!!! 警告忽略就是了
##########################################################################


################################私有库##########################################
privateSpecs='git@github.com:ET-LINK/OggAudioPlayer.git'
cocoapodsSpecs='https://github.com/CocoaPods/Specs'
#私有库校验
pod spec lint --sources='${privateSpecs},${cocoapodsSpecs}' --no-clean --private --allow-warnings --verbose
#发布私有pod
pod repo push ${frameworkName}.podspec --sources='${privateSpecs},${cocoapodsSpecs}' --verbose --allow-warnings
##########################################################################


#打包成SDK，拷贝到自己的demo目录，并且上传到github等操作
##########################################################################
pod package ${frameworkName}.podspec --force
sdkFilePath=$(cd `dirname $0`;pwd)
SDK="${sdkFilePath}/OggAudioPlayer-${version}/ios/OggAudioPlayer.framework"
#自己编写的sdk测试demo所在位置
DEMOPATH="/Users/Enter/Demo/IDZAQAudioPlayer\ 2/Frameworks"
cp -rf ${SDK} ${DEMOPATH}
##########################################################################