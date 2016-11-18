
Pod::Spec.new do |spec|
	spec.name         = 'INLConfig'
	spec.version      = '1.0'
	spec.platform     = :ios, '8.0'
	spec.license      = { :type => 'CC0 1.0' }
	spec.homepage     = 'https://github.com/inloop/INLConfig'
	spec.authors      = { 'Tomas Hakel' => 'tomas.hakel@inloop.eu' }
	spec.summary      = 'An iOS library for loading your configuration from a plist that supports automatic code generation for supporting code and remote updates'
	spec.source =  { :git => 'https://github.com/inloop/INLConfig.git', :tag => spec.version }

	spec.source_files = 'INLConfig/INLConfig/*.{h,m,swift}'
	spec.resources = ['genconfig']

	spec.dependency 'SwiftyJSON'
end
