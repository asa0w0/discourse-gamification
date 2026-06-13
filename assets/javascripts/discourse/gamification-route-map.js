export default function () {
  this.route("gamificationLeaderboard", { path: "/leaderboard" }, function () {
    this.route("byName", { path: "/:leaderboardId" });
    this.route("shop", { path: "/shop" });
  });

  this.route("user", { path: "/u/:username" }, function () {
    this.route("inventory", { path: "/inventory" });
  });
}
