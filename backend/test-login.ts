import "dotenv/config";
import fetch from "node-fetch"; // or just use native fetch if Node >= 18

async function main() {
  const res = await fetch('http://localhost:3000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@nala.com', password: 'password123' })
  });
  const text = await res.text();
  console.log('Status:', res.status);
  console.log('Response:', text);
}
main();
