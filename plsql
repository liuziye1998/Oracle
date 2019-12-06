声明部分(declaration section):关键字declare
    声明部分包含了常量，变量的数据类型和初始值，游标也在这部分声明，由关键字DECLARE开始

执行部分(executable section)：关键字begin
    执行部分是pl/sql块中的指令部分，由关键字begin开始，所有的可执行语句都放在这一部分

异常处理部分
    此部分是可选的，这一部分中处理异常或错误

语法部分：
    每一条语句以分号结束，每一个PL/SQL块以begin或declare开始，以end结束，注释由--标示

    关键字using用于给绑定变量赋值
    例如：
        declare 
            vc_sql_1 varchar2(4000);
            vc_sql_2 varchar2(4000);
            n_temp_1 number;
            n_temp_2 number;
        begin
            vc_sql_1 := 'insert into emp(empno,ename,job) values(:1,:2,:3)';
            executable immediate vc_sql_1 using 7370,'cuihua2'.'dba';
            n_temp_1 :=sql%rowcount;
            vc_sql_2 := 'insert into emp(empno,ename,job) values(:1,:1,:3)';
            executable immediate vc_sql_1 using 7371,'cuihua3'.'dba';
            n_temp_2 :=sql%rowcount;
            dbms_output.put_line(to_char(n_temp_1+n_temp_2));
            commit;
        end;
        /
        目标SQL中有几个绑定变量，关键字using后面就需要跟几个具体输入的值(各值之间以逗号分隔)，与直接用exec给绑定变量赋值有区别
        对于上述使用绑定变量的方式，关键字using后传入的绑定变量具体输入值只于对应变量所处的位置关系有关，与其名称无关，意味着只要
        变量所处的位置不同，他们对应的变量名称是可以相同的

        关键字returning可以和带有绑定变量的目标SQL连用，其目的是把受该SQL(通常指DML语句)影响的行记录的对应字段找出来

pl/spl中批量绑定的典型用法
    批量绑定是一种优化后的使用绑定变量的方式，依然使用常规的方式来使用绑定变量，其优势在于批量绑定一次处理一批数据，而不是一次处理
    一条数据，所以此方法可以有效减少pl/sql引擎和sql引擎上下文切换的次数，即交互的次数
        pl/sql引擎可简单看作Oracle数据库中专门处理pl/sql代码中除SQL语句之外所有剩余部分(如变量，赋值，循环，数组等)的子系统
        sql引擎是Oracle数据库中专门处理SQL语句的子系统，pl/sql引擎和sql引擎上下文切换就是指他们之间的交互
    影响pl/sql代码性能有影响的主要有如下两点
        1. 显式或参考游标需要循环执行fetch操作时，这里的循环操作需要pl/sql引擎来处理，而fetch一条记录对应要执行的SQL语句需要SQL
      引擎来处理，若不做任何优化，则每fetch一条记录，pl/sql和sql引擎就要交互一次
        2. 显式或参考游标的循环内部需要执行SQL语句时，若不做任何优化，那么循环内部每执行一次SQL语句，pl/sql和sql引擎就要交互一次

    批量fetch对应的语法为: fetch cursorname bulk collect into [自定义的数组] <limit CN_batch_size>
        关键字limit cn_batch_size表示一次只批量fetch常量cn_batch_size所限制的记录数，该关键字是非必须的，若不使用该关键字，则
      会一次性把所有满足条件的记录全部fetch进来，当cursorname对应的结果集的记录数很大时，这种做法不可取，会给PGA带来很大的压力，
      进而无节制的占用PGA甚至撑爆paging space

    一次执行一批sql语句的语法如下
        forall i in 1..[自定义数组的长度]
            execute  immediate [带绑定变量的目标SQL] using [对应绑定变量的具体输入值]
            关键字forall表示一次执行一批SQL语句，可以和insert，update和delete语句连用
