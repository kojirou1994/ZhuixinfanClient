# ZhuixinfanClient



# Database
mysql database name: `zhuixinfan`
```sql
CREATE TABLE `viewresource` (
`sid` int(11) NOT NULL,
`text` text,
`ed2k` text,
`magnet` text,
`drive1` text,
`drive2` text,
PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```
