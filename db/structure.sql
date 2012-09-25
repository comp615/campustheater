CREATE TABLE `freshman` (
  `person_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  `email` varchar(80) COLLATE latin1_german2_ci NOT NULL,
  `acting` tinyint(1) NOT NULL,
  `lights` tinyint(1) NOT NULL,
  `sound` tinyint(1) NOT NULL,
  `costumes` tinyint(1) NOT NULL,
  `sets` tinyint(1) NOT NULL,
  `production` tinyint(1) NOT NULL,
  `directing` tinyint(1) NOT NULL,
  `other` tinyint(1) NOT NULL,
  PRIMARY KEY (`person_id`)
) ENGINE=MyISAM AUTO_INCREMENT=378 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci;

CREATE TABLE `news` (
  `news_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `poster` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `text` text COLLATE latin1_german2_ci NOT NULL,
  PRIMARY KEY (`news_id`)
) ENGINE=MyISAM AUTO_INCREMENT=28 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci;

CREATE TABLE `people` (
  `person_id` int(11) NOT NULL AUTO_INCREMENT,
  `fname` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  `lname` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  `email` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `year` smallint(6) NOT NULL,
  `college` varchar(2) COLLATE latin1_german2_ci NOT NULL,
  `pic` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `bio` text COLLATE latin1_german2_ci NOT NULL,
  `password` varchar(32) COLLATE latin1_german2_ci NOT NULL,
  `confirm_code` varchar(32) COLLATE latin1_german2_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `email_allow` tinyint(1) NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`person_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2640 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Table for all people who participate in theater';

CREATE TABLE `playground` (
  `play_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `writer` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `synopsis` text COLLATE latin1_german2_ci NOT NULL,
  `comments` text COLLATE latin1_german2_ci NOT NULL,
  `email` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `yale` tinyint(1) NOT NULL,
  `file` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `passw` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `approved` tinyint(1) NOT NULL DEFAULT '0',
  `written` date NOT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`play_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Holds all playground plays and information';

CREATE TABLE `positions` (
  `pos_id` smallint(6) NOT NULL AUTO_INCREMENT,
  `position` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  PRIMARY KEY (`pos_id`)
) ENGINE=MyISAM AUTO_INCREMENT=35 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Theater Positions';

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `show_auditions` (
  `aud_id` int(11) NOT NULL AUTO_INCREMENT,
  `show_id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT '2003-01-01 00:00:00',
  `signup_timestamp` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `name` varchar(100) COLLATE latin1_german2_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE latin1_german2_ci DEFAULT NULL,
  `email` varchar(255) COLLATE latin1_german2_ci DEFAULT NULL,
  `location` varchar(255) COLLATE latin1_german2_ci DEFAULT NULL,
  PRIMARY KEY (`aud_id`)
) ENGINE=MyISAM AUTO_INCREMENT=359398 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci;

CREATE TABLE `show_positions` (
  `show_pos_id` int(11) NOT NULL AUTO_INCREMENT,
  `show_id` int(11) NOT NULL,
  `pos_id` smallint(6) NOT NULL,
  `assistant` tinyint(1) NOT NULL DEFAULT '1',
  `name` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `character` varchar(100) COLLATE latin1_german2_ci NOT NULL,
  `person_id` int(11) NOT NULL,
  PRIMARY KEY (`show_pos_id`)
) ENGINE=MyISAM AUTO_INCREMENT=41748 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Positions in a show';

CREATE TABLE `show_showtimes` (
  `showtime_id` int(11) NOT NULL AUTO_INCREMENT,
  `show_id` int(11) NOT NULL,
  `time` time NOT NULL,
  `date` date NOT NULL,
  `email_sent` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`showtime_id`),
  KEY `time_index` (`date`,`time`),
  KEY `show_index` (`show_id`,`date`,`time`)
) ENGINE=MyISAM AUTO_INCREMENT=1947 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Showtimes by show';

CREATE TABLE `shows` (
  `show_id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('theater','dance','film','comedy','casting') COLLATE latin1_german2_ci NOT NULL DEFAULT 'theater',
  `title` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `writer` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `tagline` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `location` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `contact` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `auditions_enabled` tinyint(1) NOT NULL,
  `aud_date` varchar(100) COLLATE latin1_german2_ci NOT NULL,
  `aud_loc` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `aud_signup` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `aud_info` tinytext COLLATE latin1_german2_ci NOT NULL,
  `aud_files` tinytext COLLATE latin1_german2_ci NOT NULL,
  `public_aud_info` tinyint(1) NOT NULL,
  `history` text COLLATE latin1_german2_ci NOT NULL,
  `poster` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `approved` tinyint(1) NOT NULL,
  `pw` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `url_key` varchar(25) COLLATE latin1_german2_ci DEFAULT NULL,
  `alt_tix` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `seats` smallint(6) NOT NULL,
  `cap` smallint(6) NOT NULL,
  `waitlist` tinyint(1) NOT NULL,
  `show_waitlist` tinyint(1) NOT NULL DEFAULT '0',
  `tix_enabled` tinyint(1) NOT NULL,
  `freeze` smallint(6) NOT NULL,
  `on_sale` date NOT NULL,
  `insta_confirm` tinyint(1) NOT NULL,
  `archive` tinyint(1) NOT NULL DEFAULT '1',
  `archive_reminder_sent` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`show_id`)
) ENGINE=MyISAM AUTO_INCREMENT=414 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Table with main show information';

CREATE TABLE `tickets` (
  `tix_id` int(11) NOT NULL AUTO_INCREMENT,
  `fname` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  `lname` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  `email` varchar(255) COLLATE latin1_german2_ci NOT NULL,
  `num` tinyint(4) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `showtime_id` int(11) NOT NULL,
  `tix_type_id` smallint(6) NOT NULL,
  PRIMARY KEY (`tix_id`)
) ENGINE=MyISAM AUTO_INCREMENT=20455 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Reservation System';

CREATE TABLE `tickets_type` (
  `tix_type_id` smallint(6) NOT NULL AUTO_INCREMENT,
  `tix_type` varchar(50) COLLATE latin1_german2_ci NOT NULL,
  PRIMARY KEY (`tix_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1 COLLATE=latin1_german2_ci COMMENT='Types of people who reserve tickets';

