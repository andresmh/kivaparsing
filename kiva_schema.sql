create table kiva_ent(
	type ENUM('group', 'single') not null default 'single',
	time DATETIME not null,
	url varchar(255) not null,
	id mediumint not null,
	name varchar(255) not null,
	activity varchar(255) not null,
	loanamt float(20,2) not null,
	daysleft int not null,
	country varchar(255) not null,
	loan_use text not null,
	repayrate varchar(30) not null,
	lender varchar(512),
	repaid varchar(30) not null,
	listdate DATE,
	disbursmentdate DATE,
	fundraising ENUM('pilot', 'active', 'paused', 'closed'),
	timeonkiva varchar(40),
	entreponkiva int,
	totalloans float(20,2),
	delinquentrate float(3,2),
	defaultrate float(3,2),
	groupname varchar(50),
	groupmembers text,
	location varchar(255),
	currencyexchange varchar(255),
	currencyexchangeloss enum('covered', 'possible', 'n/a'),
	averageincome float(10,2),
	currency varchar(255),
	exchangerate varchar(255),
	description text not null,
	loanreq float(10,2),
	raised float(10,2),
	needed float(10,2),
	primary key(time,id)
);

create table kiva_parts(
	partnerid int,
	fieldpartner varchar(512),
	rating tinyint,
	startdate date,
	timeonkiva varchar(255),
	kivaents int,
	totalloans float(15,2),
	delinqrate float(3,2),
	defrate float(3,2),
	exchangeloss float(3,2),
	fundingstatus ENUM('pilot', 'active', 'paused', 'closed'),
	networkaffs text,
	emailcontact varchar(255),
	womenents float(3,2),
	averateloanamt float(15,2),
	aveindloan float(15,2),
	avegrploan float(15,2),
	aveentsgroup float(3,2),
	avelocalgdp float(10,2),
	aveloangdp float(3,2),
	averaised float(10,2),
	aveloanterm varchar(128),
	totaljournals int,
	journalcoverage float(3,2),
	journalkivaents float(3,2),
	journalsfreq float(3,2),
	averecommend float(5,2),
	aveinterest float(4,2),
	avelocalinterest float(4,2)
);

create table ent_stats();

