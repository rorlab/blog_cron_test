# rails runner 사용법

우선 **runner**를 하나 생성하기로 한다.

**lib/** 디렉토리에 임의 하위 디렉토리, 여기서는 `runners`이라는 하위 디렉토리를 생성한다. 그리고 이 디렉토리에 **test_runner.rb** 파일을 생성하고 아래와 같이 코드를 작성한다.

```ruby
class Runners::TestRunner
  def self.display_system_datetime
    puts "A test_runner was executed at #{Time.now}."
  end
end
```

그리고 **config/application.rb** 파일에 아래와 같이 **lib** 디렉토리를 자동으로 로딩되도록 한다.

```ruby
config.autoload_paths += %W(#{config.root}/lib)
```

그리고 커맨드라인에서 아래와 같이 실행해 본다.

```
$ rails runner Runners::TestRunner.display_system_datetime
A test_runner was executed at 2014-09-22 14:17:04 +0900.
```

또한 아래와 같이  **runner** 인수를 문자열로 지정해도 된다.

```
$ rails runner "Runners::TestRunner.display_system_datetime"
A test_runner was executed at 2014-09-22 14:17:04 +0900.
```
예약된 시간에 이 **runner**를 백그라운드에서 실행하기 위해서 **cron** 작업 설정을 편리하게 도와주는 **whenever** 젬을 사용해 보도로 하자.

이를 위해서 **whenever**라는 젬을 Gemfile에 아래와 같이 추가하고 `bundle install`한다.

```
gem 'whenever', require: false
```

그리고, **whenever** 젬 설정 파일을 생성하기 위해서 아래와 같이 명령을 실행하면,

```
$ wheneverize .
```

이제 **config** 디렉토리에 **schedule.rb** 파일이 생성된다. 이 파일을 열고 아래와 같이 설정을 한다.

```
set :environment, :development
set :bundler_path, "path_to_bundler"
set :output, {:error => 'log/error.log', :standard => 'log/cron.log'}

every 1.minute do
  runner "Runners::TestRunner.display_system_datetime"
end
```

`"path_to_bundler"`는 `which bundle` 명령으로 찾은 경로를 추가로 지정해 주면 된다. 이 때 경로 끝에 `/`는 제거해 주어야 한다.

> **주의** : **zsh** 사용할 경우에는 **schedule.rb** 파일에 `set :job_template, "zsh -l -c ':job'"` 을 추가해 주어야 한다.

이제 이 파일을 가지고 아래와 같은 명령으로  **crontab** 파일을 작성해 주어야 한다.

```
$ whenever --update-crontab runner_job
[write] crontab file updated
```

**runner_job**은 원하는 job 이름으로 대신해도 된다.

> **참고** : **runner_job**을 제거하기 위해서는 아래와 같이 명령을 실행하면 된다.
>```
>$ whenever --clear-crontab runner_job
>```

확인을 위해 아래와 같은 명령을 실행한다.

```
$ crontab -l

# Begin Whenever generated tasks for: runner_job
* * * * * /bin/bash -l -c 'cd :path && bundle exec rails runner -e development '\''Runners::TestRunner.display_system_datetime'\'' >> log/cron.log 2>> log/error.log'

# End Whenever generated tasks for: runner_job
```

이제 1분마다 위의 **runner**가 실행될 것이다. 그러나 바로 아래와 같은 에러가 발생했다. **log/error.log**의 내용은 아래와 같다.

```
/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/lib/ruby/2.0.0/rubygems/core_ext/kernel_require.rb:55:in `require': cannot load such file -- bundler/setup (LoadError)
  from /System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/lib/ruby/2.0.0/rubygems/core_ext/kernel_require.rb:55:in `require'
  from /Users/hyo/prj/lectures/biweekly71/blog/config/boot.rb:4:in `<top (required)>'
  from bin/rails:7:in `require_relative'
  from bin/rails:7:in `<main>'
```

> **참고** : **whenever** 젬에서는 기본적으로 4개의 job 형태를 제공해 준다.
>```
>  job_type :command, ":task :output"
>  job_type :rake,    "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output"
>  job_type :runner,  "cd :path && script/rails runner -e :environment ':task' :output"
>  job_type :script,  "cd :path && :environment_variable=:environment bundle exec script/:task :output"
>```

`:runner` 형의 지정에서 `rails runner`의 경로를 변경하기 위해서 **schedule.rb** 파일에 아래의 코드라인을 추가해 준다.

```
job_type :runner, "cd :path && :bundler_path/bundle exec rails runner -e :environment ':task' :output"
```

`:path`는 지정하지 않았는데, 이 경우 자동으로 **whenever**가 실행되는 현재의 경로로 지정된다. 여기서는 프로젝트의 루트로 지정된다.

이제 제대로 동작하게 된다면 **log/error.log** 파일에는 더 이상 에러가 보이지 않게 될 것이다. **log/cron.log**에 아래와 같이 보이게 된다.

```
Cron job was executed 2014-09-22 14:59:02 +0900
```

**cron.log** 파일을 모니터링하기 위해서는 아래와 같이 명령을 실행하면 된다.

```
$ tail -f log/cron.log
Cron job was executed 2014-09-22 19:50:00 +0900
Cron job was executed 2014-09-22 19:51:00 +0900
Cron job was executed 2014-09-22 19:52:00 +0900
Cron job was executed 2014-09-22 19:53:01 +0900
Cron job was executed 2014-09-22 19:54:00 +0900
Cron job was executed 2014-09-22 19:55:00 +0900
Cron job was executed 2014-09-22 19:56:00 +0900
Cron job was executed 2014-09-22 19:57:00 +0900
Cron job was executed 2014-09-22 19:58:00 +0900
...
```

> **Github 소스** : https://github.com/rorlab/blog_cron_test

----

**References** :

* [whenever 젬의 Gihub 저장소](https://github.com/javan/whenever)
* [Output redirection aka logging your cron jobs](https://github.com/javan/whenever/wiki/Output-redirection-aka-logging-your-cron-jobs)
* [Rails 4 Cron Jobs With Whenever](http://serdardogruyol.com/?p=156)
* [Rails3でバッチ処理を実行する](http://www.slowlydays.net/wordpress/?p=707)
* [Rails Runnerを使ってみる](http://masa2sei.github.io/blog/2013/02/01/rails-rails-runner/)
* [Crontab : 서버에서 주기적인 명령 실행](http://www.tested.co.kr/board/Study/view/wr_id/15/sca/5)
* [Whenever gem is not executing task](http://stackoverflow.com/a/22837274/1217633)








