
const express = require("express");
const mysql = require("mysql2/promise");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const path = require("path");

const app = express();
const PORT = 8080;
const SESSION_HOURS = 12;

// In-memory sessions only.

const sessions = Object.create(null);

app.use(express.json());
app.use(express.urlencoded({ extended: false }));


app.use(express.static(path.join(__dirname, "..", "public")));


const pool = mysql.createPool({
  host: "127.0.0.1",
  user: "root",
  password: "Rewind",
  database: "project_rewind",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});
//temp
console.log("DB CONFIG:", {
  host: "127.0.0.1",
  user: "root",
  database: "project_rewind"
});
(async () => {
  try {
    const [rows] = await pool.execute("SELECT 1");
    console.log("MySQL connection successful");
  } catch (err) {
    console.error("MySQL connection failed:", err.message);
  }
})();
//temp

function makeToken() {
  return crypto.randomBytes(24).toString("hex");
}

function ok(res, data = {}) {
  res.json({ ok: true, ...data });
}

function fail(res, status, message) {
  res.status(status).json({ ok: false, message });
}

function getTokenFromRequest(req) {
  const authHeader = req.headers.authorization || "";

  if (authHeader.startsWith("Bearer ")) {
    return authHeader.slice(7).trim();
  }

  return (req.body.token || "").trim();
}

function cleanupSessions() {
  const now = Date.now();

  for (const token in sessions) {
    if (sessions[token].expiresAt <= now) {
      delete sessions[token];
    }
  }
}

//5 min clear
setInterval(cleanupSessions, 5 * 60 * 1000);

function requireAuth(req, res, next) {
  const token = getTokenFromRequest(req);

  if (!token || !sessions[token]) {
    return fail(res, 401, "Unauthorized");
  }

  const session = sessions[token];

  if (session.expiresAt <= Date.now()) {
    delete sessions[token];
    return fail(res, 401, "Session expired");
  }

  req.user = session;
  next();
}


app.post("/api/register", async (req, res) => {
  try {
    const email = (req.body.email || "").trim() || null;
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";

    if (!username || !password) {
      return fail(res, 400, "Username and password are required");
    }

    if (username.length > 50) {
      return fail(res, 400, "Username is too long");
    }

    const passHash = await bcrypt.hash(password, 12);

    await pool.execute(
      `INSERT INTO users (email, username, pass_hash, role)
       VALUES (?, ?, ?, 'player')`,
      [email, username, passHash]
    );

    ok(res);
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      return fail(res, 409, "Username already exists");
    }

    console.error("REGISTER ERROR:", err);
    fail(res, 500, "Server error");
  }
});

// testing duh
app.get("/api/test", (req, res) => {
  res.json({ ok: true, message: "Server works" });
});

// Login for player/admin
app.post("/api/login", async (req, res) => {
  console.log("LOGIN REQUEST:", req.body);
  try {
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";
    const requestedRole = (req.body.role || "player").trim().toLowerCase();
    const adminId = (req.body.admin_id || "").trim();

    if (!username || !password) {
      return fail(res, 400, "Username and password are required");
    }

    const [rows] = await pool.execute(
      `SELECT id, username, pass_hash, role, admin_id
       FROM users
       WHERE username = ?
       LIMIT 1`,
      [username]
    );

    if (rows.length === 0) {
      return fail(res, 401, "Invalid username or password");
    }

    const user = rows[0];
    const passwordMatches = await bcrypt.compare(password, user.pass_hash);

    if (!passwordMatches) {
      return fail(res, 401, "Invalid username or password");
    }

    // Optional admin validation
    if (requestedRole === "admin") {
      if (user.role !== "admin") {
        return fail(res, 403, "This account is not an admin account");
      }

      if (user.admin_id && adminId !== user.admin_id) {
        return fail(res, 403, "Invalid admin ID");
      }
    }

    const token = makeToken();

    sessions[token] = {
      userId: user.id,
      username: user.username,
      role: user.role,
      expiresAt: Date.now() + SESSION_HOURS * 60 * 60 * 1000
    };

    ok(res, {
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role
      }
    });
  } catch (err) {
    console.error("LOGIN ERROR:", err);
    fail(res, 500, "Server error");
  }
});

app.post("/api/logout", (req, res) => {
  const token = getTokenFromRequest(req);

  if (token && sessions[token]) {
    delete sessions[token];
  }

  ok(res);
});

app.get("/api/me", requireAuth, (req, res) => {
  ok(res, {
    user: {
      id: req.user.userId,
      username: req.user.username,
      role: req.user.role
    }
  });
});



// Public lobbies 
app.get("/api/lobbies", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, description, max_participants, created_at
       FROM lobbies
       WHERE is_private = 0
       ORDER BY created_at DESC`
    );

    ok(res, { lobbies: rows });
  } catch (err) {
    console.error("GET LOBBIES ERROR:", err);
    fail(res, 500, "Server error");
  }
});

// Create a lobby
app.post("/api/lobbies", requireAuth, async (req, res) => {
  try {
    const name = (req.body.name || "").trim();
    const description = (req.body.description || "").trim();
    const isPrivate = req.body.is_private ? 1 : 0;
    const maxParticipants = Number(req.body.max_participants || 4);

    if (!name || !description) {
      return fail(res, 400, "Name and description are required");
    }

    if (![2, 3, 4].includes(maxParticipants)) {
      return fail(res, 400, "max_participants must be 2, 3, or 4");
    }

    const [result] = await pool.execute(
      `INSERT INTO lobbies
       (owner_user_id, name, description, is_private, max_participants)
       VALUES (?, ?, ?, ?, ?)`,
      [req.user.userId, name, description, isPrivate, maxParticipants]
    );

    await pool.execute(
      `INSERT INTO lobby_members (lobby_id, user_id)
       VALUES (?, ?)`,
      [result.insertId, req.user.userId]
    );

    ok(res, { lobby_id: result.insertId });
  } catch (err) {
    console.error("CREATE LOBBY ERROR:", err);
    fail(res, 500, "Server error");
  }
});

// Join a public lobby
app.post("/api/lobbies/:id/join", requireAuth, async (req, res) => {
  try {
    const lobbyId = Number(req.params.id);

    if (!lobbyId) {
      return fail(res, 400, "Invalid lobby ID");
    }

    const [lobbyRows] = await pool.execute(
      `SELECT id, is_private, max_participants
       FROM lobbies
       WHERE id = ?
       LIMIT 1`,
      [lobbyId]
    );

    if (lobbyRows.length === 0) {
      return fail(res, 404, "Lobby not found");
    }

    const lobby = lobbyRows[0];

    if (lobby.is_private) {
      return fail(res, 403, "Cannot directly join a private lobby");
    }

    const [memberCountRows] = await pool.execute(
      `SELECT COUNT(*) AS count
       FROM lobby_members
       WHERE lobby_id = ?`,
      [lobbyId]
    );

    if (memberCountRows[0].count >= lobby.max_participants) {
      return fail(res, 400, "Lobby is full");
    }

    await pool.execute(
      `INSERT IGNORE INTO lobby_members (lobby_id, user_id)
       VALUES (?, ?)`,
      [lobbyId, req.user.userId]
    );

    ok(res);
  } catch (err) {
    console.error("JOIN LOBBY ERROR:", err);
    fail(res, 500, "Server error");
  }
});


// Send invite to username 
app.post("/api/invites", requireAuth, async (req, res) => {
  try {
    const lobbyId = Number(req.body.lobby_id);
    const toUsername = (req.body.to_username || "").trim();

    if (!lobbyId || !toUsername) {
      return fail(res, 400, "lobby_id and to_username are required");
    }

    const [lobbyRows] = await pool.execute(
      `SELECT id, owner_user_id, is_private
       FROM lobbies
       WHERE id = ?
       LIMIT 1`,
      [lobbyId]
    );

    if (lobbyRows.length === 0) {
      return fail(res, 404, "Lobby not found");
    }

    const lobby = lobbyRows[0];

    if (lobby.owner_user_id !== req.user.userId) {
      return fail(res, 403, "Only the lobby owner can send invites");
    }

    if (!lobby.is_private) {
      return fail(res, 400, "Invites are only for private lobbies");
    }

    await pool.execute(
      `INSERT INTO invites (lobby_id, from_user_id, to_username, status)
       VALUES (?, ?, ?, 'pending')`,
      [lobbyId, req.user.userId, toUsername]
    );

    ok(res);
  } catch (err) {
    console.error("SEND INVITE ERROR:", err);
    fail(res, 500, "Server error");
  }
});

// Get invite 
app.get("/api/invites", requireAuth, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT i.id, i.lobby_id, i.status, i.created_at, l.name AS lobby_name
       FROM invites i
       JOIN lobbies l ON l.id = i.lobby_id
       WHERE i.to_username = ?
       ORDER BY i.created_at DESC`,
      [req.user.username]
    );

    ok(res, { invites: rows });
  } catch (err) {
    console.error("GET INVITES ERROR:", err);
    fail(res, 500, "Server error");
  }
});

// Respond to invite
app.post("/api/invites/:id/respond", requireAuth, async (req, res) => {
  try {
    const inviteId = Number(req.params.id);
    const status = (req.body.status || "").trim().toLowerCase();

    if (!inviteId) {
      return fail(res, 400, "Invalid invite ID");
    }

    if (status !== "accepted" && status !== "declined") {
      return fail(res, 400, "Status must be accepted or declined");
    }

    const [inviteRows] = await pool.execute(
      `SELECT *
       FROM invites
       WHERE id = ? AND to_username = ?
       LIMIT 1`,
      [inviteId, req.user.username]
    );

    if (inviteRows.length === 0) {
      return fail(res, 404, "Invite not found");
    }

    const invite = inviteRows[0];

    await pool.execute(
      `UPDATE invites
       SET status = ?
       WHERE id = ?`,
      [status, inviteId]
    );

    if (status === "accepted") {
      await pool.execute(
        `INSERT IGNORE INTO lobby_members (lobby_id, user_id)
         VALUES (?, ?)`,
        [invite.lobby_id, req.user.userId]
      );
    }

    ok(res);
  } catch (err) {
    console.error("RESPOND INVITE ERROR:", err);
    fail(res, 500, "Server error");
  }
});
app.post("/api/register", async (req, res) => {
  try {
    const email = (req.body.email || "").trim() || null;
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";

    if (!username || !password) {
      return fail(res, 400, "Username and password are required");
    }

    if (username.length > 50) {
      return fail(res, 400, "Username is too long");
    }

    const passHash = await bcrypt.hash(password, 12);

    const [result] = await pool.execute(
      `INSERT INTO users (email, username, pass_hash, role)
       VALUES (?, ?, ?, 'player')`,
      [email, username, passHash]
    );

    await pool.execute(
      `INSERT INTO player_stats (user_id, kills, deaths, time_played_seconds)
       VALUES (?, 0, 0, 0)`,
      [result.insertId]
    );

    ok(res);
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      return fail(res, 409, "Username already exists");
    }

    console.error("REGISTER ERROR:", err);
    fail(res, 500, "Server error");
  }
});

app.get("/api/leaderboard", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT 
         u.username,
         ps.kills,
         ps.deaths,
         ps.time_played_seconds
       FROM player_stats ps
       JOIN users u ON u.id = ps.user_id
       ORDER BY ps.kills DESC, ps.deaths ASC, ps.time_played_seconds DESC
       LIMIT 50`
    );

    ok(res, { leaderboard: rows });
  } catch (err) {
    console.error("LEADERBOARD ERROR:", err);
    fail(res, 500, "Server error");
  }
});
//do not forget to Rewind server password and "StrongPasswordHere!" is not a strong passward
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

app.post("/api/stats/update", requireAuth, async (req, res) => {
  try {
    const addKills = Number(req.body.kills || 0);
    const addDeaths = Number(req.body.deaths || 0);
    const addTime = Number(req.body.time_played_seconds || 0);

    await pool.execute(
      `UPDATE player_stats
       SET
         kills = kills + ?,
         deaths = deaths + ?,
         time_played_seconds = time_played_seconds + ?
       WHERE user_id = ?`,
      [addKills, addDeaths, addTime, req.user.userId]
    );

    ok(res);
  } catch (err) {
    console.error("UPDATE STATS ERROR:", err);
    fail(res, 500, "Server error");
  }
});

app.get("/api/stats/me", requireAuth, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT kills, deaths, time_played_seconds
       FROM player_stats
       WHERE user_id = ?
       LIMIT 1`,
      [req.user.userId]
    );

    if (rows.length === 0) {
      return fail(res, 404, "Stats not found");
    }

    ok(res, { stats: rows[0] });
  } catch (err) {
    console.error("MY STATS ERROR:", err);
    fail(res, 500, "Server error");
  }
});