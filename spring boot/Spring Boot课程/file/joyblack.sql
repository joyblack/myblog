/*
Navicat MySQL Data Transfer

Source Server         : docker
Source Server Version : 50505
Source Host           : 10.21.1.47:3306
Source Database       : joyblack

Target Server Type    : MYSQL
Target Server Version : 50505
File Encoding         : 65001

Date: 2018-12-20 09:45:44
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `department`
-- ----------------------------
DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `id` int(11) NOT NULL,
  `department_name` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of department
-- ----------------------------
INSERT INTO `department` VALUES ('1', '乡下冒险者公会');
INSERT INTO `department` VALUES ('2', '城市冒险者公会');

-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `login_name` varchar(20) NOT NULL,
  `department_id` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES ('1', '阿库娅', 'akuya', '1');
INSERT INTO `user` VALUES ('2', '克里斯汀娜', 'crustina', '1');
INSERT INTO `user` VALUES ('3', '惠惠', 'huihui', '1');