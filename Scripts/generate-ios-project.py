#!/usr/bin/env python3
"""Generate the small iPhone Xcode project without external build dependencies."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
objects = {}
def item(identifier, **fields):
    objects[identifier] = fields
    return identifier

source = item('PHONE_SOURCE', isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path='Apps/iOS/UltronPhoneApp.swift', sourceTree='<group>')
product = item('PHONE_PRODUCT', isa='PBXFileReference', explicitFileType='wrapper.application', path='ULTRON.app', sourceTree='BUILT_PRODUCTS_DIR')
main = item('MAIN_GROUP', isa='PBXGroup', children=[source, 'PRODUCT_GROUP'], sourceTree='<group>')
item('PRODUCT_GROUP', isa='PBXGroup', children=[product], name='Products', sourceTree='<group>')
item('SOURCE_BUILD', isa='PBXBuildFile', fileRef=source)
item('SOURCES', isa='PBXSourcesBuildPhase', buildActionMask=2147483647, files=['SOURCE_BUILD'], runOnlyForDeploymentPostprocessing=0)
item('FRAMEWORKS', isa='PBXFrameworksBuildPhase', buildActionMask=2147483647, files=['CORE_BUILD', 'UI_BUILD', 'LINK_BUILD'], runOnlyForDeploymentPostprocessing=0)
item('LOCAL_PACKAGE', isa='XCLocalSwiftPackageReference', relativePath='.')
for name, module in [('CORE', 'UltronCore'), ('UI', 'UltronUI'), ('LINK', 'UltronLink')]:
    item(name, isa='XCSwiftPackageProductDependency', productName=module)
    item(name + '_BUILD', isa='PBXBuildFile', productRef=name)
for name in ['Debug', 'Release']:
    item('PROJECT_' + name, isa='XCBuildConfiguration', name=name, buildSettings={
        'SDKROOT': 'iphoneos', 'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SWIFT_VERSION': '6.0',
        'ALWAYS_SEARCH_USER_PATHS': 'NO',
        'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if name == 'Debug' else '-O'})
    item('TARGET_' + name, isa='XCBuildConfiguration', name=name, buildSettings={
        'PRODUCT_BUNDLE_IDENTIFIER': 'dev.ultron.phone', 'PRODUCT_NAME': 'ULTRON',
        'GENERATE_INFOPLIST_FILE': 'YES', 'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
        'INFOPLIST_KEY_NSLocalNetworkUsageDescription': 'Connect to your Mac over an encrypted local connection only when you request pairing.',
        'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
        'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
        'MARKETING_VERSION': '0.6.0', 'CURRENT_PROJECT_VERSION': '6',
        'CODE_SIGN_STYLE': 'Automatic'})
for kind in ['PROJECT', 'TARGET']:
    item(kind + '_CONFIG', isa='XCConfigurationList', buildConfigurations=[kind + '_Debug', kind + '_Release'], defaultConfigurationIsVisible=0, defaultConfigurationName='Release')
item('PHONE_TARGET', isa='PBXNativeTarget', buildConfigurationList='TARGET_CONFIG', buildPhases=['SOURCES', 'FRAMEWORKS'], buildRules=[], dependencies=[], name='UltronPhone', packageProductDependencies=['CORE', 'UI', 'LINK'], productName='ULTRON', productReference=product, productType='com.apple.product-type.application')
item('PROJECT', isa='PBXProject', attributes={'LastUpgradeCheck': '2620'}, buildConfigurationList='PROJECT_CONFIG', compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings=0, knownRegions=['en', 'Base'], mainGroup=main, productRefGroup='PRODUCT_GROUP', projectDirPath='', projectRoot='', packageReferences=['LOCAL_PACKAGE'], targets=['PHONE_TARGET'])

def render(value):
    if isinstance(value, dict):
        return '{\n' + '\n'.join(json.dumps(str(k)) + ' = ' + render(v) + ';' for k, v in value.items()) + '\n}'
    if isinstance(value, list): return '(' + ', '.join(render(v) for v in value) + ')'
    return json.dumps(value)

project = root / 'ULTRON.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n' + render(dict(archiveVersion=1, classes={}, objectVersion=56, objects=objects, rootObject='PROJECT')) + '\n')
print(project)
