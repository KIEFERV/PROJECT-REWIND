CREATE DATABASE IF NOT EXISTS project_rewind;
USE project_rewind;

-- Users 
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(120) NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  pass_hash VARCHAR(255) NOT NULL,
  role ENUM('player','admin') NOT NULL DEFAULT 'player',
  admin_id VARCHAR(32) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions 
CREATE TABLE sessions (
  token VARCHAR(128) PRIMARY KEY,
  user_id INT NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Lobbies
CREATE TABLE lobbies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_user_id INT NOT NULL,
  name VARCHAR(80) NOT NULL,
  description TEXT NOT NULL,
  is_private TINYINT(1) NOT NULL DEFAULT 0,
  max_participants INT NOT NULL DEFAULT 4,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Lobby members
CREATE TABLE lobby_members (
  lobby_id INT NOT NULL,
  user_id INT NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (lobby_id, user_id),
  FOREIGN KEY (lobby_id) REFERENCES lobbies(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Invites 
CREATE TABLE invites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  lobby_id INT NOT NULL,
  from_user_id INT NOT NULL,
  to_username VARCHAR(50) NOT NULL,
  status ENUM('pending','accepted','declined') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lobby_id) REFERENCES lobbies(id) ON DELETE CASCADE,
  FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE
);