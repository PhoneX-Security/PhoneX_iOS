platform :ios, '8.0'
# pod 'CocoaLumberjack' ... in submoduled xmppFramework
# pod 'CocoaAsyncSocket' ... in submoduled xmppFramework

target "Phonex" do
	use_frameworks!

	# Cocoa lumberjack
	pod 'CocoaLumberjack'

	# CocoaAsyncSocket, for XPPFramework
	pod 'CocoaAsyncSocket', '~> 7.5.0'

	# KissXML for XMPPFramework
	pod 'KissXML/SwiftNSXML', '~> 5.1.2'

	# Local XMPP Framework
	pod "XMPPFramework", :path => "dependency/XMPPFramework/XMPPFramework"

	# Protocol buffers
	#pod 'GoogleProtobuf'
	pod 'ProtocolBuffers', '1.9.2'

	# Google analytics
	#pod 'Google/Analytics'
	#, '~> 1.0.0'

	# Flurry crash report engine
	pod 'Flurry-iOS-SDK/FlurrySDK'

	# Application invitation, unused
	# pod 'Google/AppInvite'

	# Input vield validator
	pod 'AJWValidator'

	# TTTAttributedLabel by Matt Thompson (NSHipster)
	pod 'TTTAttributedLabel'

  	# Certificate pinning
	#pod 'TrustKit'

	# From some deps reasons
	#pod 'GoogleNetworkingUtilities'
end

