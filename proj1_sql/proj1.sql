-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1:
create or replace view Q1_85course(student) as
select student from course_enrolments
where mark>=85
group by student
having count(course)>20;

create or replace view Q1_8520(id) as
select id from students,Q1_85course
where students.id=Q1_85course.student and students.stype='intl';

create or replace view Q1(unswid, name) as
select people.unswid,people.name
from people,Q1_8520
where people.id=Q1_8520.id;



-- Q2:
create or replace view all_rooms(unswid,longname,building) as
select rooms.unswid,rooms.longname,rooms.building
from rooms,room_types
where rooms.rtype=room_types.id and room_types.description='Meeting Room'
and rooms.capacity>=20;

create or replace view Q2(unswid,name) as
select all_rooms.unswid,all_rooms.longname
from all_rooms,buildings
where all_rooms.building=buildings.id
and buildings.name='Computer Science Building';



-- Q3:
create or replace view S_Bs_course(courseid) as
select course from course_enrolments,people
where course_enrolments.student=people.id and people.name='Stefan Bilek';

create or replace view Q3(unswid, name) as
select people.unswid,people.name
from people,course_staff,S_Bs_course
where course_staff.staff=people.id
and course_staff.course=S_Bs_course.courseid;


-- Q4:
create or replace view COMP3331(course) as
select courses.id from courses,subjects
where courses.subject=subjects.id
and subjects.code='COMP3331';

create or replace view COMP3231(course) as
select courses.id from courses,subjects
where courses.subject=subjects.id
and subjects.code='COMP3231';

create or replace view COMP3331_S(student) as
select student from course_enrolments,COMP3331
where course_enrolments.course=COMP3331.course;

create or replace view COMP3231_S(student) as
select student from course_enrolments,COMP3231
where course_enrolments.course=COMP3231.course;

create or replace view Study3_not_2(student) as
(select * from COMP3331_S)
except
(select * from COMP3231_S);

create or replace view Q4(unswid, name) as
select unswid,name
from people,Study3_not_2
where people.id=Study3_not_2.student;





-- Q5:
create or replace view SNC(pid) as
select partOf
from stream_enrolments,streams
where streams.id=stream_enrolments.stream
and streams.name='Chemistry';

create or replace view local_students(id) as
select id from students
where stype='local';

create or replace view chemistry_student(id) as
select program_enrolments.student
from program_enrolments,SNC
where program_enrolments.id=SNC.pid
and semester=
(select semesters.id from semesters
where year=2011 and term='S1');

create or replace view LCStudent(id) as
select * from chemistry_student
intersect
select * from local_students;

create or replace view Q5a(num) as
select count(*) from LCStudent;



-- Q5:
create or replace view CSEprogram(id) as 
select programs.id from programs,orgunits
where programs.offeredby=orgunits.id
and orgunits.longname='School of Computer Science and Engineering';

create or replace view CSE_11S1_students(id) as
select program_enrolments.student from program_enrolments,CSEprogram,Semesters
where program_enrolments.program=CSEprogram.id
and program_enrolments.semester=
(select semesters.id from semesters
where year=2011 and term='S1');

create or replace view international_student(id) as
select id from students where stype='intl';

create or replace view int_cse_11s1_student(id) as
select * from CSE_11S1_students
intersect
select * from international_student;

create or replace view Q5b(num) as
select count(*) from int_cse_11s1_student;



-- Q6:
create or replace function
	Q6(text) returns text
as
$$

select code||' '||name||' '||uoc
from subjects where code=$1;


$$ language sql;



-- Q7:
create or replace view program_student(id,count_of_student) as
select program,count(student)
from program_enrolments
group by program;

create or replace view program_interstu(id,student) as
select program_enrolments.program,program_enrolments.student
from program_enrolments,international_student
where program_enrolments.student=international_student.id;

create or replace view program_COinterstu(id,count_of_student) as
select id,count(student) from program_interstu
group by id;

create or replace view Q7_programid(id) as
select program_COinterstu.id from program_COinterstu,program_student
where program_COinterstu.id=program_student.id
and program_COinterstu.count_of_student>(program_student.count_of_student*0.1)/(2*0.1);

create or replace view Q7(code, name) as
select programs.code,programs.name
from programs,Q7_programid
where programs.id=Q7_programid.id;



-- Q8:
create or replace view mark_not_null(course,count_of_mark) as
select course,count(course) from course_enrolments
where mark is not null
group by course;

create or replace view course_tobe_calculated(course,mark) as
select course_enrolments.course,course_enrolments.mark
from course_enrolments,mark_not_null
where course_enrolments.course=mark_not_null.course
and mark_not_null.count_of_mark>=15;

create or replace view course_avg_mark(course,mark) as
select course,avg(mark) from course_tobe_calculated
group by course;

create or replace view highest_avgmark_course(course) as 
select course from course_avg_mark
where mark=(select max(mark) from course_avg_mark);

create or replace view subj_seme(subject,semester) as
select subject,semester from courses,highest_avgmark_course
where highest_avgmark_course.course=courses.id;

create or replace view Q8(code,name,semester) as
select subjects.code,subjects.name,semesters.name
from semesters,subjects,subj_seme
where subj_seme.semester=semesters.id
and subj_seme.subject=subjects.id;



-- Q9:

create or replace view actually_school(id) as
select orgunits.id from orgunits,orgunit_types
where orgunit_types.id=orgunits.utype
and orgunit_types.name='School';

create or replace view new_affiliations_1(staff,orgunit,role,starting) as
select staff,orgunit,role,starting from affiliations   
where isPrimary='t' and ending is null;

create or replace view new_affiliations_2(staff,orgunit,role,starting) as
select new_affiliations_1.staff,new_affiliations_1.orgunit,new_affiliations_1.role,new_affiliations_1.starting
from new_affiliations_1,actually_school
where new_affiliations_1.orgunit=actually_school.id;

create or replace view new_affiliations_3(staff,orgunit,role,starting) as
select new_affiliations_2.staff,new_affiliations_2.orgunit,new_affiliations_2.role,new_affiliations_2.starting
from new_affiliations_2,staff_roles
where new_affiliations_2.role=(select staff_roles.id from staff_roles where staff_roles.name='Head of School');

create or replace view new_affiliations_4(staff,orgunit,role,starting) as
select distinct * from new_affiliations_3;

create or replace view staff_and_course(staff,course) as
select course_staff.staff,course_staff.course
from course_staff,new_affiliations_4
where new_affiliations_4.staff=course_staff.staff;

create or replace view staff_and_subject(staff,subject) as
select staff_and_course.staff,subjects.code
from staff_and_course,courses,subjects
where staff_and_course.course=courses.id and courses.subject=subjects.id;

create or replace view staff_and_subject_nore(staff,subject) as
select distinct * from staff_and_subject
order by staff;

create or replace view staff_and_ContOfsubject(staff,count_of_subject) as
select staff,count(subject) from staff_and_subject_nore
group by staff;

create or replace view Q9(name,school,email,starting,num_subjects) as
select people.name,orgunits.longname,people.email,new_affiliations_4.starting,staff_and_ContOfsubject.count_of_subject
from people,orgunits,new_affiliations_4,staff_and_ContOfsubject
where people.id=new_affiliations_4.staff and orgunits.id=new_affiliations_4.orgunit
and staff_and_ContOfsubject.staff=new_affiliations_4.staff;



-- Q10:
create or replace view COMP_subjects(id,code,name,firstoffer,lastoffer) as
select id,code,name,firstoffer,lastoffer from subjects where code like 'COMP93%';

create or replace view major_semester(id,unswid,year,term,name,starting,ending) as
select id,unswid,cast(year as char(4)),term,name,starting,ending from semesters
where starting>'2002-12-31' and ending<'2013-01-01' and (term='S1' or term='S2');

create or replace view COM93_courses(id,semester) as
select courses.id as id,substring(major_semester.year,3,2)||''||major_semester.term as semester
from courses,major_semester,COMP_subjects
where courses.subject=COMP_subjects.id and courses.semester=major_semester.id;

create or replace view subject_and_opentime(subject,semester) as
select COMP_subjects.id,COM93_courses.semester
from COMP_subjects,COM93_courses,courses
where COMP_subjects.id=courses.subject and COM93_courses.id=courses.id;

create or replace view subject_and_opentime_fi(subject,semester) as
select distinct * from subject_and_opentime;

create or replace view subject_and_countOfot(subject,count_of_semester) as
select subject,count(semester) from subject_and_opentime_fi 
group by subject;

create or replace view subject_canbe_used(subject) as
select subject from subject_and_countOfot where count_of_semester=20;

create or replace view valid_mark(subject,course,semester,mark,student) as
select subject_canbe_used.subject,course_enrolments.course,COM93_courses.semester,course_enrolments.mark,course_enrolments.student
from course_enrolments,COM93_courses,subject_canbe_used,courses
where courses.subject=subject_canbe_used.subject and COM93_courses.id=courses.id
and courses.id=course_enrolments.course and course_enrolments.mark>=0;

create or replace view valid_mark_fi(subject,semester,mark) as
select subject,semester,cast(mark as integer) from valid_mark;

create or replace view mark_count(subject,semester,count_of_mark) as
select subject,semester,count(mark)
from valid_mark_fi
group by subject,semester
order by subject,semester;

create or replace view HD_mark_count(subject,semester,count_of_mark) as
select subject,semester,count(mark)
from valid_mark_fi
where mark>=85
group by subject,semester;

create or replace view new_HD_mark_count(subject,semester,count_of_mark) as
select mark_count.subject,mark_count.semester,HD_mark_count.count_of_mark
from mark_count
left join HD_mark_count
on mark_count.subject=HD_mark_count.subject and mark_count.semester=HD_mark_count.semester;

create or replace view new_HD_mark_count_fi(subject,semester,count_of_mark) as
select subject,semester,case when count_of_mark is null then 0 else count_of_mark end as count_of_mark_1
from new_HD_mark_count;

create or replace view HD_rate(subject,semester,rate) as
select new_HD_mark_count_fi.subject,new_HD_mark_count_fi.semester,cast((new_HD_mark_count_fi.count_of_mark*0.1)/(mark_count.count_of_mark*0.1) as numeric(4,2))
from new_HD_mark_count_fi,mark_count
where mark_count.subject=new_HD_mark_count_fi.subject and new_HD_mark_count_fi.semester=mark_count.semester;

create or replace view HD_rate_S1(subject,semester,rate) as
select * from HD_rate where semester like '%S1';

create or replace view HD_rate_S2(subject,semester,rate) as
select * from HD_rate where semester like '%S2';

create or replace view HD_rate_S1_S2(subject,semesterS1,semesterS2,rateS1,rateS2) as
select HD_rate_S1.subject,HD_rate_S1.semester,HD_rate_S2.semester,HD_rate_S1.rate,HD_rate_S2.rate
from HD_rate_S1
left join HD_rate_S2
on HD_rate_S1.subject=HD_rate_S2.subject and substring(HD_rate_S1.semester,1,2)=substring(HD_rate_S2.semester,1,2);

create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate) as
select subjects.code,subjects.name,substring(HD_rate_S1_S2.semesters1,1,2),HD_rate_S1_S2.rates1,HD_rate_S1_S2.rates2
from subjects,HD_rate_S1_S2
where subjects.id=HD_rate_S1_S2.subject;


