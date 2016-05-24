require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name                = "Skelet"
  s.version             = package['version']
  s.summary             = package['description']
  s.description         = <<-DESC
                            SkeletCodeEditor
                         DESC
  s.homepage            = "http://skeletcode.com/"
  s.license             = package['license']
  s.author              = "Facebook"
  s.source              = { :git => "https://github.com/skeletcode/skelet.git", :tag => "v#{s.version}" }
  s.default_subspec     = 'Core'
  s.requires_arc        = true
  s.platform            = :osx, "10.10"
  s.preserve_paths      = "cli", "src", "node_modules", "package.json"

  s.subspec 'Core' do |ss|
    ss.source_files     = "osx/skelet/**/*.{c,h,m,mm,S}"
    ss.exclude_files    = "**/__tests__/*", "Modules/*",
      "Images/*", "AppDelegate*.*", "main.m",
  end
end
