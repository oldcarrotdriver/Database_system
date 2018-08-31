--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
declare
	room_information    record;
	nb_of_student       integer;
	nb_of_wait_student  integer;
	nb_of_total_student integer;
	room_capacity       RoomRecord;
begin
	if not exists(select * from courses where id = course_id) then
	   raise exception 'INVALID COURSEID';
	end if;
	nb_of_student := (select count(student) from course_enrolments where course=course_id);
	nb_of_wait_student := (select count(student) from course_enrolment_waitlist where course=course_id);
	nb_of_total_student := nb_of_student + nb_of_wait_student;
	room_capacity.valid_room_number := 0;
	room_capacity.bigger_room_number := 0;
	for room_information in select * from rooms order by id
	loop
		if (room_information.capacity >= nb_of_student) then
		   room_capacity.valid_room_number := room_capacity.valid_room_number + 1;
		   if (room_information.capacity >= nb_of_total_student) then
		      room_capacity.bigger_room_number := room_capacity.bigger_room_number + 1;
		   end if;
		end if;
	end loop;
	return room_capacity;
end;
$$ language plpgsql;


--Q2:


drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare
	tuple_of_staff      record;
	course_enrol        record;
	OneTeachingRecord   TeachingRecord % rowtype;
	count_stu_number    integer;
	median_mark	        integer;
	sum_of_two_mark     integer;
begin

create or replace view new_semester(id, term) as
select semesters.id as id, substring(cast(semesters.year as char(4)),3,2)||''||lower(semesters.term) as term
from semesters;

create or replace view staff_course_information(staffid, course, semester, code, name, uoc, average_mark, highest_mark, nb_of_students) as
select course_staff.staff, courses.id, new_semester.term, subjects.code, subjects.name, subjects.uoc,
round((sum(course_enrolments.mark)*0.1)/(count(course_enrolments.mark)*0.1)), max(course_enrolments.mark), count(course_enrolments.mark)
from course_staff, courses, new_semester, subjects, course_enrolments
where course_staff.course = courses.id and
courses.semester = new_semester.id and
courses.subject = subjects.id and course_staff.course = course_enrolments.course
group by course_staff.staff, courses.id, new_semester.term, subjects.code, subjects.name, subjects.uoc;


	if not exists (select * from staff where id = staff_id) then
	   raise exception 'INVALID STAFFID';
	end if;
	for tuple_of_staff in select * from staff_course_information where staff_course_information.staffid = staff_id
	loop
		median_mark := 0;
		count_stu_number := 1;
		if tuple_of_staff.nb_of_students % 2 <> 0 then
		   for course_enrol in select * from course_enrolments where course_enrolments.course = tuple_of_staff.course order by mark
		   loop
			if count_stu_number = round(tuple_of_staff.nb_of_students/2) + 1 then
			   median_mark := course_enrol.mark;
			   OneTeachingRecord.median_mark := median_mark;
			   exit;
			end if;
			count_stu_number := count_stu_number + 1;
		   end loop;
		end if;
		if tuple_of_staff.nb_of_students % 2 = 0 then
		   sum_of_two_mark := 0;
		   for course_enrol in select * from course_enrolments where course_enrolments.course = tuple_of_staff.course order by mark
		   loop
			if count_stu_number = round(tuple_of_staff.nb_of_students/2) then
			   sum_of_two_mark := sum_of_two_mark + course_enrol.mark;
			end if;
			if count_stu_number = round(tuple_of_staff.nb_of_students/2) + 1 then
			   sum_of_two_mark := sum_of_two_mark + course_enrol.mark;
			   median_mark := round(sum_of_two_mark/2);
			   OneTeachingRecord.median_mark := median_mark;
			   exit;
			end if;
			count_stu_number := count_stu_number + 1;
		   end loop;
		end if;
		OneTeachingRecord.cid = tuple_of_staff.course;
		OneTeachingRecord.term = tuple_of_staff.semester;
		OneTeachingRecord.code = tuple_of_staff.code;
		OneTeachingRecord.name = tuple_of_staff.name;
		OneTeachingRecord.uoc = tuple_of_staff.uoc;
		OneTeachingRecord.average_mark = tuple_of_staff.average_mark;
		OneTeachingRecord.highest_mark = tuple_of_staff.highest_mark;
		OneTeachingRecord.totalenrols = tuple_of_staff.nb_of_students;
		return next OneTeachingRecord;
	end loop;
	return;
end;
$$ language plpgsql;



--Q3:


drop type if exists Queried_students cascade;
create type Queried_students as (unswid integer);

create or replace function setof_students(orgni_id integer, num_courses integer, min_score integer)
	returns setof Queried_students
as $$
declare
	tuple_of_students    record;
	needed_students      Queried_students % rowtype;
begin

create or replace view org_subject_course(orgid, orgid_name, subjects_code, subjects_name, course_id, student_unswid, mark, course_semester) as
select subjects.offeredby, orgunits.name, subjects.code, subjects.name, courses.id, people.unswid, 
case when course_enrolments.mark is null then 0 else course_enrolments.mark end as mark_1, semesters.name
from subjects, courses, semesters, course_enrolments, people, students, orgunits
where subjects.offeredby = orgunits.id and people.id = students.id and students.id = course_enrolments.student and
courses.subject = subjects.id and courses.id = course_enrolments.course and courses.semester = semesters.id
order by course_enrolments.student, subjects.offeredby, course_enrolments.mark DESC, courses.id ASC;

	for tuple_of_students in 
		select student_unswid as sid, count(*) as count, max(mark) as max from org_subject_course 
		where org_subject_course.orgid in 
		(with recursive t as(select member, owner from orgunit_groups where owner <> member and owner = orgni_id
		union all 
		select k.member, k.owner from orgunit_groups k ,t where t.member = k.owner) select t.member from t)
		or org_subject_course.orgid = orgni_id
		group by student_unswid
	loop
		if tuple_of_students.count > num_courses and tuple_of_students.max >= min_score then
			needed_students.unswid := tuple_of_students.sid;
			return next needed_students;
		end if;
	end loop;
	return;
end;
$$ language plpgsql;



drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
	returns setof CourseRecord
as $$
declare
	tuple_of_record     record;
	one_student         record;
	final_courseRecord  CourseRecord % rowtype;
	course_record       text;
	whole_course_record text;
	counter_of_number   integer;
	saved_place_uid     integer;
	saved_place_sname   text;
	one_mark_record     text;


begin
	if not exists (select * from orgunits where orgunits.id = org_id) then
	   raise exception 'INVALID ORGID';
	end if;

	for one_student in(
		select * from setof_students(org_id, num_courses, min_score)
		)
	loop
		saved_place_uid := one_student.unswid;
		saved_place_sname := (select people.name from people where people.unswid = one_student.unswid);
		whole_course_record := '';
		counter_of_number := 1;
		for tuple_of_record in(
			select * from org_subject_course 
			where org_subject_course.student_unswid = saved_place_uid
			and (org_subject_course.orgid in 
			(with recursive t as(select member, owner from orgunit_groups where owner <> member and owner = org_id
			union all 
			select k.member, k.owner from orgunit_groups k ,t where t.member = k.owner) select t.member from t)
			or org_subject_course.orgid = org_id)
			order by student_unswid, mark DESC, course_id ASC
			)
		loop
			if counter_of_number <= 5 then
				one_mark_record := cast(tuple_of_record.mark as text);
				if one_mark_record = '0' then
				 	one_mark_record := 'null';
			    end if;
				course_record := tuple_of_record.subjects_code||', '||tuple_of_record.subjects_name
						||', '||tuple_of_record.course_semester||', '||tuple_of_record.orgid_name
						||', '||one_mark_record||chr(10);
				whole_course_record := whole_course_record||''||course_record;
				counter_of_number := counter_of_number + 1;
				final_courseRecord.course_records := whole_course_record;
			else exit;
			end if;
		end loop;
		final_courseRecord.unswid := saved_place_uid;
		final_courseRecord.student_name := saved_place_sname;
		return next final_courseRecord;
	end loop;
	return;
end;
$$ language plpgsql;