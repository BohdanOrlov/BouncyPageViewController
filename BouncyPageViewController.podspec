
Pod::Spec.new do |s|
  s.name             = 'BouncyPageViewController'
  s.version          = '0.1.0'
  s.summary          = 'Page view controller with bounce effect'


  s.description      = <<-DESC
Page view controller with bounce effect inspired by motion design by Stan Yakushevish.
                       DESC

  s.homepage         = 'https://github.com/BohdanOrlov/BouncyPageViewController'
  s.screenshots      = 'https://github.com/BohdanOrlov/BouncyPageViewController/blob/master/GIFs/dribble.gif?raw=true', 'https://github.com/BohdanOrlov/BouncyPageViewController/blob/master/GIFs/bouncyDemo.gif?raw=true'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bohdan Orlov' => 'bohdan.orlov@gmail.com' }
  s.source           = { :git => 'https://github.com/BohdanOrlov/BouncyPageViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bohdan_orlov'

  s.ios.deployment_target = '8.0'

  s.source_files = 'BouncyPageViewController/Classes/**/*'
  s.dependency 'RBBAnimation', '0.4.0'
end
