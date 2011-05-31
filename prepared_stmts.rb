require 'user'
require 'benchmark'

User.delete_all

user = User.create!(:name => 'aaron')

conn = ActiveRecord::Base.connection
p "###### Before querying"
p :prepare => Hash[conn.execute('SHOW GLOBAL STATUS').to_a]['Com_stmt_prepare']
p :execute => Hash[conn.execute('SHOW GLOBAL STATUS').to_a]['Com_stmt_execute']

1000.times do
  conn.exec_query('SELECT * FROM `users` WHERE `id` = ?', 'SQL', [[nil, user.id]])
end

p "###### After querying"
p :prepare => Hash[conn.execute('SHOW GLOBAL STATUS').to_a]['Com_stmt_prepare']
p :execute => Hash[conn.execute('SHOW GLOBAL STATUS').to_a]['Com_stmt_execute']

N = 10_000
Benchmark.bm(13) do |x|
  stmt_sql    = 'SELECT * FROM `users` WHERE `id` = ?'
  bind_params = [[nil, user.id]]

  exec_sql    = "SELECT * FROM `users` WHERE `id` = #{user.id}"

  x.report('prepared stmt') {
    N.times { conn.exec_query(stmt_sql, 'SQL', bind_params) }
  }
  x.report('execute') {
    N.times { conn.execute(exec_sql) }
  }
end

__END__
On my system:

[aaron@higgins hello (master)]$ RAILS_ENV=production ruby script/rails runner prepared_stmts.rb 
"###### Before querying"
{:prepare=>"30"}
{:execute=>"2037"}
"###### After querying"
{:prepare=>"31"}
{:execute=>"3037"}
                   user     system      total        real
prepared stmt 10.580000   0.330000  10.910000 ( 12.084159)
execute        9.840000   0.280000  10.120000 ( 11.494407)
[aaron@higgins hello (master)]$ 
  
