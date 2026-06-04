create schema typemodtest;
create type typemodtest.my_rec as (
	coll_no_typemod              collection,
	coll_typemod_int             collection('int'),
	icoll_no_typemod             icollection,
	icollection_typemod_varchar  icollection('varchar')
);
\d typemodtest.my_rec
drop schema typemodtest cascade;