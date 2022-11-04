Pod::Spec.new do |spec|
  spec.name         = "SlidingBanner"
  spec.version      = "0.0.1"
  spec.summary      = "Animated sliding banner for custom in app notifications or other sliding views, written in Swift"

  spec.description  = <<-DESC
  Simple and light weight library allowing custom views to slide from different directions of the screen with animation. The library can manage when and how to dismiss the banner. Lightweight and Very easy to setup.
                   DESC

  spec.homepage     = "http://augarte/SlidingBanner"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Aimar Ugarte" => "ugarteaimar@gmail.com" }

  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "http://github.com/augarte/SlidingBanner.git", :tag => "#{spec.version}" }

  spec.source_files  = "Classes", "Sources/*.swift"
end
