Pod::Spec.new do |s|
  s.name         = "AFGridView"
  s.version      = "0.0.1"
  s.summary      = "Multiple directions scrolling grid view"
  s.homepage     = "https://github.com/AppFellas/AFGridView"
  s.license      = 'MIT'
  s.author       = { "AppFellas" => "info@appfellas.co" }
  s.source       = { :git => "https://github.com/AppFellas/AFGridView.git" }
  s.source_files = 'AFGridView/**/*.{h.m}'
  s.platform     = :ios
  s.requires_arc = true
end
