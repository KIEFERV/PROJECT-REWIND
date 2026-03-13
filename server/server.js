const express = require("express");
const mysql = require("mysql2/promise");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const path = require("path");

const PORT = 8080;
const SESSION_DAYS = 7;

const app = express();


app.use(express.urlencoded({ extended: false }));
app.use(express.json());


app.use(express.static(path.join(__dirname, "public")));

//kill me now
const pool = mysql.createPool({
  host: "localhost",
  user: "DB_USER",
  password: "DB_PASS",
  database: "project_rewind",
  waitForConnections: true,
  connectionLimit: 10,
});


function makeToken() {
  return crypto.randomBytes(32).toString("hex"); // 64-char hex
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function ok(res, data = {}) {
  return res.json({ ok: true, ...data });
}

function fail(res, status, code, message) {
  return res.status(status).json({ ok: false, code, message });
}


function readToken(req) {
  const auth = req.header("authorization") || "";
  if (auth.toLowerCase().startsWith("bearer ")) return auth.slice(7).trim();

  const x = (req.header("x-token") || "").trim();
  if (x) return x;

  return (req.body.token || "").trim();
}

//bastard child
async function requireAuth(req, res, next) {
  try {
    const token = readToken(req);
    if (!token) return fail(res, 401, "UNAUTH", "Missing token");

    const [rows] = await pool.execute(
      `SELECT u.id, u.username, u.role
       FROM sessions s
       JOIN users u ON u.id = s.user_id
       WHERE s.token = ? AND s.expires_at > NOW()
       LIMIT 1`,
      [token]
    );

    if (!rows.length) return fail(res, 401, "UNAUTH", "Invalid or expired token");

    req.user = rows[0];
    next();
  } catch (err) {
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
}

app.post("/api/register", async (req, res) => {
  try {
    const email = (req.body.email || "").trim() || null;
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";

    if (!username || !password) return fail(res, 400, "EMPTY", "Username and password required");
    if (username.length > 50) return fail(res, 400, "USERLEN", "Username too long");

    const passHash = await bcrypt.hash(password, 12);

    await pool.execute(
      `INSERT INTO users(email, username, pass_hash, role)
       VALUES(?, ?, ?, 'player')`,
      [email, username, passHash]
    );

    return ok(res);
  } catch (err) {
    if (err?.code === "ER_DUP_ENTRY") return fail(res, 409, "TAKEN", "Username already exists");
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
});

app.post("/api/login", async (req, res) => {
  try {
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";

    if (!username || !password) return fail(res, 400, "EMPTY", "Username and password required");

    const [rows] = await pool.execute(
      "SELECT id, username, pass_hash, role FROM users WHERE username=? LIMIT 1",
      [username]
    );

    if (!rows.length) return fail(res, 401, "INVALID_LOGIN", "Bad username or password");

    const user = rows[0];
    const okPass = await bcrypt.compare(password, user.pass_hash);
    if (!okPass) return fail(res, 401, "INVALID_LOGIN", "Bad username or password");

    const token = makeToken();
    const expiresAt = addDays(new Date(), SESSION_DAYS);

    await pool.execute(
      "INSERT INTO sessions(token, user_id, expires_at) VALUES(?, ?, ?)",
      [token, user.id, expiresAt]
    );

    return ok(res, { token, username: user.username, role: user.role });
  } catch (err) {
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
});

// why not 
app.post("/api/logout", requireAuth, async (req, res) => {
  try {
    const token = readToken(req);
    await pool.execute("DELETE FROM sessions WHERE token=?", [token]);
    return ok(res);
  } catch (err) {
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
});

// "Who am I"
app.get("/api/me", requireAuth, async (req, res) => {
  return ok(res, { user: req.user });
});


app.get("/api/lobbies", async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, description, max_participants
       FROM lobbies
       WHERE is_private = 0
       ORDER BY created_at DESC
       LIMIT 100`
    );
    return ok(res, { lobbies: rows });
  } catch (err) {
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
});


app.post("/api/lobbies", requireAuth, async (req, res) => {
  try {
    const name = (req.body.name || "").trim();
    const description = (req.body.description || "").trim();
    const isPrivate = req.body.is_private ? 1 : 0;
    const max = Number(req.body.max_participants || 4);

    if (!name || !description) return fail(res, 400, "EMPTY", "Name and description required");
    if (![2, 3, 4].includes(max)) return fail(res, 400, "BAD_MAX", "max_participants must be 2, 3, or 4");

    const [result] = await pool.execute(
      `INSERT INTO lobbies(owner_user_id, name, description, is_private, max_participants)
       VALUES(?, ?, ?, ?, ?)`,
      [req.user.id, name, description, isPrivate, max]
    );


    await pool.execute(
      "INSERT INTO lobby_members(lobby_id, user_id) VALUES(?, ?)",
      [result.insertId, req.user.id]
    );

    return ok(res, { lobby_id: result.insertId });
  } catch (err) {
    console.error(err);
    return fail(res, 500, "SERVER", "Server error");
  }
});

//do not forget to Rewind server password and "StrongPasswordHere!" is not a strong passward
app.listen(PORT, () => {
  console.log(`Local server running: http://localhost:${PORT}`);
});