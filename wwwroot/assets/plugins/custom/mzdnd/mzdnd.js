(function (window) {
    'use strict';

    var options = {
        inputId: '', // input file id
        zoneId: '', // drag zone box id
        message: '', // message below drag zone
        type: '', // content type : image | video | zip
        defaultImg: '', // set default img : URL
        clickDefaultURL: null, // new window url address for default image click : URL
        videoIcon:
            'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeG1sbnM6c3ZnanM9Imh0dHA6Ly9zdmdqcy5jb20vc3ZnanMiIHZlcnNpb249IjEuMSIgd2lkdGg9IjUxMiIgaGVpZ2h0PSI1MTIiIHg9IjAiIHk9IjAiIHZpZXdCb3g9IjAgMCA0NzcuODY3IDQ3Ny44NjciIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDUxMiA1MTIiIHhtbDpzcGFjZT0icHJlc2VydmUiIGNsYXNzPSIiPjxnPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgoJPGc+CgkJPHBhdGggZD0iTTQ2OS43NzcsMTIyLjAxYy01LjAzMS0zLjExMS0xMS4zMTUtMy4zOTUtMTYuNjA2LTAuNzUxbC0xMTEuODM4LDU1LjkyN3YtNDAuNjUzYzAtMjguMjc3LTIyLjkyMy01MS4yLTUxLjItNTEuMkg1MS4yICAgIGMtMjguMjc3LDAtNTEuMiwyMi45MjMtNTEuMiw1MS4ydjIwNC44YzAsMjguMjc3LDIyLjkyMyw1MS4yLDUxLjIsNTEuMmgyMzguOTMzYzI4LjI3NywwLDUxLjItMjIuOTIzLDUxLjItNTEuMnYtNDAuNjUzICAgIGwxMTEuODM4LDU2LjAxM2M4LjQzMiw0LjIxMywxOC42ODIsMC43OTQsMjIuODk2LTcuNjM4YzEuMTk4LTIuMzk3LDEuODE1LTUuMDQzLDEuOC03LjcyMnYtMjA0LjggICAgQzQ3Ny44NywxMzAuNjE3LDQ3NC44MDksMTI1LjEyMiw0NjkuNzc3LDEyMi4wMXogTTMwNy4yLDM0MS4zMzNjMCw5LjQyNi03LjY0MSwxNy4wNjctMTcuMDY3LDE3LjA2N0g1MS4yICAgIGMtOS40MjYsMC0xNy4wNjctNy42NDEtMTcuMDY3LTE3LjA2N3YtMjA0LjhjMC05LjQyNiw3LjY0MS0xNy4wNjcsMTcuMDY3LTE3LjA2N2gyMzguOTMzYzkuNDI2LDAsMTcuMDY3LDcuNjQxLDE3LjA2NywxNy4wNjcgICAgVjM0MS4zMzN6IE00NDMuNzMzLDMxMy43MmwtMTAyLjQtNTEuMnYtNDcuMTcybDEwMi40LTUxLjJWMzEzLjcyeiIgZmlsbD0iIzY2NjY2NiIgZGF0YS1vcmlnaW5hbD0iIzAwMDAwMCIgc3R5bGU9IiIgY2xhc3M9IiIvPgoJPC9nPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+Cgk8Zz4KCQk8cGF0aCBkPSJNMTcwLjY2NywxNzAuNjY3Yy0zNy43MDMsMC02OC4yNjcsMzAuNTY0LTY4LjI2Nyw2OC4yNjdzMzAuNTY0LDY4LjI2Nyw2OC4yNjcsNjguMjY3czY4LjI2Ny0zMC41NjQsNjguMjY3LTY4LjI2NyAgICBTMjA4LjM2OSwxNzAuNjY3LDE3MC42NjcsMTcwLjY2N3ogTTE3MC42NjcsMjczLjA2N2MtMTguODUxLDAtMzQuMTMzLTE1LjI4Mi0zNC4xMzMtMzQuMTMzYzAtMTguODUxLDE1LjI4Mi0zNC4xMzMsMzQuMTMzLTM0LjEzMyAgICBzMzQuMTMzLDE1LjI4MiwzNC4xMzMsMzQuMTMzQzIwNC44LDI1Ny43ODUsMTg5LjUxOCwyNzMuMDY3LDE3MC42NjcsMjczLjA2N3oiIGZpbGw9IiM2NjY2NjYiIGRhdGEtb3JpZ2luYWw9IiMwMDAwMDAiIHN0eWxlPSIiIGNsYXNzPSIiLz4KCTwvZz4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8L2c+PC9zdmc+Cg==',
        closeIcon:
            'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+DQo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHhtbG5zOnN2Z2pzPSJodHRwOi8vc3ZnanMuY29tL3N2Z2pzIiB2ZXJzaW9uPSIxLjEiIHdpZHRoPSI1MTIiIGhlaWdodD0iNTEyIiB4PSIwIiB5PSIwIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgY2xhc3M9IiI+PGc+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHRyYW5zZm9ybT0idHJhbnNsYXRlKDEgMSkiPg0KCTxnPg0KCQk8Zz4NCgkJCTxwYXRoIGQ9Ik00MzYuMDE2LDczLjk4NGMtOTkuOTc5LTk5Ljk3OS0yNjIuMDc1LTk5Ljk3OS0zNjIuMDMzLDAuMDAyYy05OS45NzgsOTkuOTc4LTk5Ljk3OCwyNjIuMDczLDAuMDA0LDM2Mi4wMzEgICAgIGM5OS45NTQsOTkuOTc4LDI2Mi4wNSw5OS45NzgsMzYyLjAyOS0wLjAwMkM1MzUuOTk1LDMzNi4wNTksNTM1Ljk5NSwxNzMuOTY0LDQzNi4wMTYsNzMuOTg0eiBNNDA1Ljg0OCw0MDUuODQ0ICAgICBjLTgzLjMxOCw4My4zMTgtMjE4LjM5Niw4My4zMTgtMzAxLjY5MSwwLjAwNGMtODMuMzE4LTgzLjI5OS04My4zMTgtMjE4LjM3Ny0wLjAwMi0zMDEuNjkzICAgICBjODMuMjk3LTgzLjMxNywyMTguMzc1LTgzLjMxNywzMDEuNjkxLDBTNDg5LjE2MiwzMjIuNTQ5LDQwNS44NDgsNDA1Ljg0NHoiIGZpbGw9IiNlNWU2ZTciIGRhdGEtb3JpZ2luYWw9IiMwMDAwMDAiIHN0eWxlPSIiIGNsYXNzPSIiLz4NCgkJCTxwYXRoIGQ9Ik0zNjAuNTkyLDE0OS40MDhjLTguMzMxLTguMzMxLTIxLjgzOS04LjMzMS0zMC4xNywwbC03NS40MjUsNzUuNDI1bC03NS40MjUtNzUuNDI1Yy04LjMzMS04LjMzMS0yMS44MzktOC4zMzEtMzAuMTcsMCAgICAgcy04LjMzMSwyMS44MzksMCwzMC4xN2w3NS40MjUsNzUuNDI1TDE0OS40MywzMzAuNGMtOC4zMzEsOC4zMzEtOC4zMzEsMjEuODM5LDAsMzAuMTdjOC4zMzEsOC4zMzEsMjEuODM5LDguMzMxLDMwLjE3LDAgICAgIGw3NS4zOTctNzUuMzk3bDc1LjQxOSw3NS40MTljOC4zMzEsOC4zMzEsMjEuODM5LDguMzMxLDMwLjE3LDBjOC4zMzEtOC4zMzEsOC4zMzEtMjEuODM5LDAtMzAuMTdsLTc1LjQxOS03NS40MTlsNzUuNDI1LTc1LjQyNSAgICAgQzM2OC45MjMsMTcxLjI0NywzNjguOTIzLDE1Ny43NCwzNjAuNTkyLDE0OS40MDh6IiBmaWxsPSIjZTVlNmU3IiBkYXRhLW9yaWdpbmFsPSIjMDAwMDAwIiBzdHlsZT0iIiBjbGFzcz0iIi8+DQoJCTwvZz4NCgk8L2c+DQo8L2c+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPC9nPg0KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4NCjwvZz4NCjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8L2c+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPC9nPg0KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4NCjwvZz4NCjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8L2c+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPC9nPg0KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4NCjwvZz4NCjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8L2c+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPC9nPg0KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4NCjwvZz4NCjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8L2c+DQo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPC9nPg0KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4NCjwvZz4NCjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8L2c+DQo8L2c+PC9zdmc+DQo',
        zipIcon:
            'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeG1sbnM6c3ZnanM9Imh0dHA6Ly9zdmdqcy5jb20vc3ZnanMiIHZlcnNpb249IjEuMSIgd2lkdGg9IjUxMiIgaGVpZ2h0PSI1MTIiIHg9IjAiIHk9IjAiIHZpZXdCb3g9IjAgMCA0ODIuMTM5IDQ4Mi4xMzkiIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDUxMiA1MTIiIHhtbDpzcGFjZT0icHJlc2VydmUiIGNsYXNzPSIiPjxnPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgoJPHBhdGggZD0iTTIyNy4yNjcsMTE3Ljg1NGMwLTguMDA2LTUuNTQ3LTEyLjc4Mi0xNS4zNjYtMTIuNzgyYy0zLjk4OCwwLTYuNjk5LDAuMzk2LTguMTE4LDAuNzc0djI1LjY4OSAgIGMxLjY3MiwwLjM3OCwzLjczNiwwLjUwNCw2LjU3MywwLjUwNEMyMjAuODA1LDEzMi4wMzksMjI3LjI2NywxMjYuNzYsMjI3LjI2NywxMTcuODU0eiIgZmlsbD0iIzY2NjY2NiIgZGF0YS1vcmlnaW5hbD0iIzAwMDAwMCIgc3R5bGU9IiIgY2xhc3M9IiIvPgoJPHBhdGggZD0iTTM1Ny4xNjMsMEgxNjMuNTE2QzEzNS4yMjYsMCwxMTIuMiwyMy4wNDEsMTEyLjIsNTEuMzE1djkuNTA0SDIzLjc3N0MxMi4zNTksNjAuODE5LDMuMSw3MC4wNywzLjEsODEuNDk2djEwNS4yOTUgICBjMCwxMS40MjYsOS4yNTksMjAuNjc4LDIwLjY3NywyMC42NzhIMTEyLjJ2MjIzLjM1NWMwLDI4LjMwNSwyMy4wMjYsNTEuMzE1LDUxLjMxNSw1MS4zMTVoMjY0LjIyMyAgIGMyOC4yNzMsMCw1MS4zLTIzLjAxLDUxLjMtNTEuMzE1VjEyMS40NDlMMzU3LjE2MywweiBNMTM1LjA2OSwxNzcuODU1SDY3LjQ1N3YtMTAuNTc1bDQxLjQxOC01OS42MjF2LTAuNTJoLTM3LjU1di0xNi4yNWg2My4wOTcgICB2MTEuMzQ5bC00MC41MjEsNTguODQ4djAuNTA1aDQxLjE2NlYxNzcuODU1eiBNMzA5LjYxNiw0MzQuOTIyYy02LjQ2Miw4Ljk4My0yMS41MzcsOC45ODMtMjcuOTgyLDAgICBjLTMuMjIzLTQuNTA4LTQuMDgzLTEwLjMyMi0yLjMwMi0xNS41NTVsNC4xNjEtMTIuMjE2aDI0LjI1NGw0LjE2MSwxMi4yMTZDMzEzLjY4OCw0MjQuNiwzMTIuODMsNDMwLjQxNCwzMDkuNjE2LDQzNC45MjJ6ICAgIE00MjcuNzM5LDQ1MC43MTNIMzE2LjU2NWMyLjI5My0xLjg1OSw0LjQxNC0zLjkzOSw2LjE3LTYuMzk3YzYuMjQ5LTguNzQ3LDcuOTEzLTIwLjAxNyw0LjQ0NC0zMC4xNDlsLTEyLjM5NS0zNi40MjJ2LTQxLjA3MyAgIGMwLTQuNDI5LTMuNTk0LTguMDIxLTguMDIyLTguMDIxaC0yMi4yODZjLTQuNDI4LDAtOC4wMjEsMy41OTItOC4wMjEsOC4wMjF2NDEuMDczbC0xMi4zOTcsMzYuNDIyICAgYy0zLjQ2NiwxMC4xMzMtMS44MDQsMjEuNDAyLDQuNDUzLDMwLjE0OWMxLjc1NywyLjQ1OCwzLjg2OCw0LjUzOCw2LjE2Miw2LjM5N0gxNjMuNTE2Yy0xMC45NTMsMC0xOS44NzMtOC45Mi0xOS44NzMtMTkuODg5ICAgVjIwNy40NjloMTQwLjk3NnYzMS41NTFsLTMwLjMwNywwLjAxN2MtNC40MzYsMC04LjAzLDMuNTk0LTguMDMsOC4wMjJ2MTcuNTczYzAsNC40MjksMy41OTQsOC4wMjEsOC4wMyw4LjAyMWgzMC4zMDd2MjUuNTggICBjMCw0LjQyOCwzLjU5NCw4LjAyMyw4LjAyMyw4LjAyM2g0NC4zMDJjNC40MjksMCw4LjAyMi0zLjU5NSw4LjAyMi04LjAyM3YtMTcuNTU4YzAtNC40MjktMy41OTQtOC4wMjItOC4wMjItOC4wMjJoLTMwLjMwNyAgIHYtMzMuNjE2bC0wLjA1MS0wLjAxN2gzMC4zNTdjNC40MjksMCw4LjAyMi0zLjU5Miw4LjAyMi04LjAyMXYtMTcuNTU4YzAtNC40MjgtMy41OTQtOC4wMjEtOC4wMjItOC4wMjFIMjkyLjA1ICAgYzcuMDQ0LTMuMjk1LDEyLjAwMS0xMC4zMzksMTIuMDAxLTE4LjYyOVY4MS40OTZjMC0xMS40MjYtOS4yNTktMjAuNjc3LTIwLjY3Ny0yMC42NzdIMTQzLjY0M3YtOS41MDQgICBjMC0xMC45MzgsOC45Mi0xOS44NTgsMTkuODczLTE5Ljg1OGwxODEuODktMC4xODl2NjcuMjM0YzAsMTkuNjM3LDE1LjkzNCwzNS41ODYsMzUuNTg3LDM1LjU4Nmw2NS44NjMtMC4xODlsMC43NDEsMjk2LjkyNSAgIEM0NDcuNTk3LDQ0MS43OTMsNDM4LjY5Miw0NTAuNzEzLDQyNy43MzksNDUwLjcxM3ogTTE0Ny40ODksMTc3Ljg1NVY5MC44ODloMTkuNzQ4djg2Ljk2NkgxNDcuNDg5eiBNMTg0LjI4OCwxNzcuODU1VjkyLjAzOSAgIGM2LjA2OC0xLjAyNCwxNC41OTQtMS43OTYsMjYuNTg4LTEuNzk2YzEyLjEzNSwwLDIwLjc3MiwyLjMxNywyNi41ODgsNi45NjZjNS41NDcsNC4zODEsOS4yODEsMTEuNjE2LDkuMjgxLDIwLjEyNiAgIGMwLDguNTEyLTIuODM1LDE1Ljc0NS03Ljk5LDIwLjY0NWMtNi43MTMsNi4zMi0xNi42NTgsOS4xNTgtMjguMjczLDkuMTU4Yy0yLjU2OSwwLTQuOTAxLTAuMTI3LTYuNjk5LTAuMzc4djMxLjA5NEgxODQuMjg4eiIgZmlsbD0iIzY2NjY2NiIgZGF0YS1vcmlnaW5hbD0iIzAwMDAwMCIgc3R5bGU9IiIgY2xhc3M9IiIvPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjxnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjwvZz4KPGcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9nPgo8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8L2c+CjwvZz48L3N2Zz4K',
        width: '200px', // set drag zone width
        height: '200px', // set drag zone height
        border: '2px #42d1f5 solid', // set drag zone border
        borderRadius: '8px', // set drag zone border radius
        isHideInput: true, // set file input hide or not : bool
        readonly: false, // set readonly : bool
        onChange: null, // onchange event callback : function
        onClose: null, // onclose event callback : function
    };

    var callbackObj = {
        width: null,
        height: null,
        duration: null,
        file: null,
    };

    function dndAlert(message) {
        if (swal) {
            swal({
                title: '',
                text: message,
                type: 'warning',
            });
        } else {
            alert(message);
        }
    }

    function extend(a, b) {
        var key;
        for (key in b) {
            if (b.hasOwnProperty(key)) {
                a[key] = b[key];
            }
        }
        return a;
    }

    function $id(id) {
        return document.getElementById(id);
    }

    function getImageWidthHeight(file, callback) {
        var _URL = window.URL || window.webkitURL;
        var img = new Image();
        var objectUrl = _URL.createObjectURL(file);
        img.onload = function () {
            var width = this.width,
                height = this.height;
            _URL.revokeObjectURL(objectUrl);
            if (callback && typeof callback === 'function') {
                callback({
                    width: width,
                    height: height,
                    filename: file.name,
                });
            }
        };
        img.src = objectUrl;
    }

    function getVideoDuration(file, callback) {
        let video = document.createElement('video');
        video.preload = 'metadata';
        video.onloadedmetadata = function () {
            var duration = this.duration;
            if (callback && typeof callback === 'function') {
                callback({
                    duration: secondToHHMMSS(duration),
                });
            }
        };
        video.src = window.URL.createObjectURL(file);
    }

    function secondToHHMMSS(second) {
        return new Date(second * 1000).toISOString().substr(11, 8);
    }

    function DnD(userOptions) {
        var newOptions = extend({}, options);
        this.options = extend(newOptions, userOptions);
    }

    DnD.prototype.secondToHHMMSS = function (second) {
        return secondToHHMMSS(second);
    };

    DnD.prototype.init = function () {
        var options = this.options;
        //console.log(options);
        // call initialization file
        if (window.File && window.FileList && window.FileReader) {
            // validation
            if (!$id(options.inputId) || !$id(options.zoneId)) {
                dndAlert('Cannot find the ID.');
                return;
            }
            if (!options.type) {
                dndAlert('please set the file type.');
            }
            // set message
            if (options.message) {
                $id(options.zoneId).insertAdjacentHTML('beforeend', '<span class="mzdnd_message">' + options.message + '</span>');
            }
            // set component style
            $id(options.zoneId).style.position = 'relative';
            _init();
        } else {
            dndAlert('브라우저가 MZDnD의 구성 요소를 지원하지 않습니다.');
        }

        function _init() {
            var filedrag = $id(options.zoneId);
            var fileselect = $id(options.inputId);

            if (!options.readonly) {
                // file select
                fileselect.addEventListener('change', _fileSelectHandler, false);

                // file drop
                filedrag.addEventListener('dragover', _fileDragHover, false);
                filedrag.addEventListener('dragleave', _fileDragHover, false);
                filedrag.addEventListener('drop', _fileSelectHandler, false);

                // zone click
                filedrag.addEventListener('click', _zoneClickHandler, false);
            }
            // set init style
            filedrag.style.display = 'inline-block';
            filedrag.style.overflow = 'hidden';
            filedrag.style.width = options.width;
            filedrag.style.height = options.height;
            filedrag.style.border = options.border;
            filedrag.style.borderRadius = options.borderRadius;
            _toggleDragZoneClass(true);
            if (options.isHideInput) fileselect.style.display = 'none';

            // default Thumbnail
            // make thumb
            _makeDefaultThumb();
        }

        function _toggleDragZoneClass(bool) {
            var filedrag = $id(options.zoneId);
            if (bool) {
                filedrag.classList.add('mzdnd_empty');
            } else {
                filedrag.classList.remove('mzdnd_empty');
            }
        }

        function _makeDefaultThumb() {
            if (options.type && options.type === 'image' && options.defaultImg) {
                _toggleMessage(false);
                $id(options.zoneId).insertAdjacentHTML(
                    'beforeend',
                    '<img class="mzdnd_img_thumb mzdnd_pointer" src="' + options.defaultImg + '" onClick="window.open(\'' + (options.clickDefaultURL ? options.clickDefaultURL : options.defaultImg) + '\')" />',
                );
                if (!options.readonly) _makeCloseBtn();
                _toggleDragZoneClass(false);
            } else if (options.type && options.type === 'video' && options.defaultImg) {
                _toggleMessage(false);
                if (options.defaultImg === 'default')
                    $id(options.zoneId).insertAdjacentHTML(
                        'beforeend',
                        '<img class="mzdnd_video_thumb ' +
                            (options.clickDefaultURL ? 'mzdnd_pointer' : '') +
                            '" src="' +
                            options.videoIcon +
                            '" style="width: ' +
                            $('#' + options.zoneId).width() * 0.4 +
                            'px" ' +
                            (options.clickDefaultURL ? 'onclick="window.open(\'' + options.clickDefaultURL + '\')"' : '') +
                            ' />',
                    );
                else
                    $id(options.zoneId).insertAdjacentHTML(
                        'beforeend',
                        '<img class="mzdnd_video_thumb ' +
                            (options.clickDefaultURL ? 'mzdnd_pointer' : '') +
                            '" src="' +
                            options.defaultImg +
                            '" ' +
                            (options.clickDefaultURL ? 'onclick="window.open(\'' + options.clickDefaultURL + '\')"' : '') +
                            ' />',
                    );
                if (!options.readonly) _makeCloseBtn();
                _toggleDragZoneClass(false);
            } else if (options.type && options.type === 'zip' && options.defaultImg) {
                _toggleMessage(false);
                if (options.defaultImg === 'default')
                    $id(options.zoneId).insertAdjacentHTML(
                        'beforeend',
                        '<img class="mzdnd_zip_thumb ' +
                            (options.clickDefaultURL ? 'mzdnd_pointer' : '') +
                            '" src="' +
                            options.zipIcon +
                            '" style="width: ' +
                            $('#' + options.zoneId).width() * 0.4 +
                            'px" ' +
                            (options.clickDefaultURL ? 'onclick="window.open(\'' + options.clickDefaultURL + '\')"' : '') +
                            ' />',
                    );
                else
                    $id(options.zoneId).insertAdjacentHTML(
                        'beforeend',
                        '<img class="mzdnd_zip_thumb ' + (options.clickDefaultURL ? 'mzdnd_pointer' : '') + '" src="' + options.defaultImg + '" ' + (options.clickDefaultURL ? 'onclick="window.open(\'' + options.clickDefaultURL + '\')"' : '') + ' />',
                    );
                if (!options.readonly) _makeCloseBtn();
                _toggleDragZoneClass(false);
            }
        }

        function _zoneClickHandler(e) {
            e.stopPropagation();
            e.preventDefault();
            var fileselect = $id(options.inputId);
            if (!fileselect.files || !fileselect.files.length) {
                fileselect.click();
            }
        }

        // file drag hover
        function _fileDragHover(e) {
            e.stopPropagation();
            e.preventDefault();
            if (e.type == 'dragover') {
                $id(options.zoneId).classList.add('mzdnd_hover');
            } else {
                $id(options.zoneId).classList.remove('mzdnd_hover');
            }
        }

        // file selection
        function _fileSelectHandler(e) {
            // cancel event and hover styling
            _fileDragHover(e);

            // fetch FileList object
            var files = e.target.files || e.dataTransfer.files;
            _addFileFromInput(files);

            // process all File objects
            for (var i = 0, f; (f = files[i]); i++) {
                if (!_parseFile(f)) break;
            }
        }

        async function _getFileVolume(file) {
            if (file.type !== 'video/mp4') return;

            var reader = new FileReader();
            const exe = new Promise(resolve => {
                reader.onload = function (event) {
                    var arrayBuffer = event.target.result;

                    // Web Audio API를 사용하기 위해 오디오 컨텍스트를 생성합니다.
                    var audioContext = new (window.AudioContext || window.webkitAudioContext)();

                    // ArrayBuffer를 오디오 버퍼로 디코딩합니다.
                    audioContext.decodeAudioData(arrayBuffer, function (decodedData) {
                        // 오디오 버퍼에서 채널 데이터를 가져옵니다.
                        var channelData = decodedData.getChannelData(0); // 0은 첫 번째 채널을 나타냅니다.

                        // 볼륨 크기를 콘솔에 출력합니다.
                        let maxVolume = -1;
                        for (let volume of channelData) {
                            if (volume > maxVolume) maxVolume = volume;
                        }
                        console.log(channelData);
                        console.log('볼륨 크기:', maxVolume);

                        // 오디오 컨텍스트를 종료합니다.
                        audioContext.close();

                        resolve(maxVolume);
                    });
                };

                // FileReader를 사용하여 MP4 파일을 읽습니다.
                reader.readAsArrayBuffer(file);
            });
            return await exe.then();
        }

        function _parseFile(file) {
            // _getFileVolume(file);
            var fileName = file.name,
                fileType = file.type,
                fileSize = file.size;

            if (fileSize > options.limitSize) {
                $id(options.inputId).files = null;
                $id(options.inputId).value = null;
                let sizeNumber = options.limitSize / 1024 / 1024 / 1024;
                let unit = 'GB';
                if (sizeNumber < 1) {
                    sizeNumber *= 1024;
                    unit = 'MB';
                }
                if (sizeNumber < 1) {
                    sizeNumber *= 1024;
                    unit = 'KB';
                }
                dndAlert(`Please upload files smaller than ${sizeNumber}${unit}.`);
                resolve(0);
                return;
            }

            // 이미지 썸네일
            // 일단 사용자가 파일을 하나만 올린다고 본다.
            if (options.type && options.type === 'image') {
                // check file type
                if (fileType.indexOf('image/gif') === -1 && fileType.indexOf('image/jpg') === -1 && fileType.indexOf('image/jpeg') === -1 && fileType.indexOf('image/png') === -1 && fileType.indexOf('image/bmp') === -1) {
                    dndAlert('This image format is not supported.\n Please check the file format.\n(jpg, jpeg, png, bmp, gif 파일 형식을 지원합니다.)');
                    $id(options.inputId).files = null;
                    $id(options.inputId).value = null;
                    return 0;
                }

                // get info
                getImageWidthHeight(file, function (value) {
                    if (options.onChange && typeof options.onChange === 'function') {
                        var o = extend({}, callbackObj);
                        options.onChange(
                            extend(o, {
                                file: file,
                                width: value.width,
                                height: value.height,
                            }),
                        );
                    }
                });

                // make thumb
                _makeImageThumb(file);
                return 1;
                // 비디오 썸네일
            } else if (options.type && options.type === 'video') {
                // check file type
                if (fileType !== 'video/mp4') {
                    $id(options.inputId).files = null;
                    $id(options.inputId).value = null;
                    dndAlert('Please upload mp4 file.');
                    return 0;
                }

                // get info
                getVideoDuration(file, function (value) {
                    if (options.onChange && typeof options.onChange === 'function') {
                        var o = extend({}, callbackObj);
                        options.onChange(
                            extend(o, {
                                file: file,
                                duration: value.duration,
                            }),
                        );
                    }
                });

                // make thumb
                _doVideoProcess(file);
                return 1;
                // zip 썸네일
            } else if (options.type && options.type === 'zip') {
                // check file type
                if (fileType.indexOf('application/x-zip-compressed') === -1) {
                    dndAlert('Please upload zip file.');
                    $id(options.inputId).files = null;
                    $id(options.inputId).value = null;
                    return 0;
                }

                if (options.onChange && typeof options.onChange === 'function') {
                    var o = extend({}, callbackObj);
                    options.onChange(
                        extend(o, {
                            file: file,
                        }),
                    );
                }

                // make thumb
                _makeZipThumb(file);
                return 1;
            }
            // 다른 형식은 허용하지 않음
            $id(options.inputId).files = null;
            $id(options.inputId).value = null;
            return 0;
        }

        function _makeImageThumb(file) {
            // image Thumb
            var reader = new FileReader();

            reader.onload = function (e) {
                // hide message
                _toggleMessage(false);

                // make thumb
                $id(options.zoneId).insertAdjacentHTML('beforeend', '<img class="mzdnd_img_thumb" src="' + e.target.result + '"/>');

                // make close btn
                _makeCloseBtn();
            };
            reader.readAsDataURL(file);
            _toggleDragZoneClass(false);
        }

        function _makeZipThumb(file) {
            // hide message
            _toggleMessage(false);

            // make thumb
            $id(options.zoneId).insertAdjacentHTML('beforeend', '<img class="mzdnd_zip_thumb" src="' + options.zipIcon + '" style="width: ' + $('#' + options.zoneId).width() * 0.4 + 'px""/>');

            // make close btn
            _makeCloseBtn();
            _toggleDragZoneClass(false);
        }

        function _makeCloseBtn(e) {
            $id(options.zoneId).insertAdjacentHTML('beforeend', '<button class="mzdnd_close_btn"><img src="' + options.closeIcon + '"/>');
            var el = document.querySelector('#' + options.zoneId + ' .mzdnd_close_btn');
            el.addEventListener('click', function (e) {
                e.stopPropagation();
                e.preventDefault();

                
                //wk 20250725 추가 삭제 전에 확인
                swalConfirm({
                    text: 'Once deleted, this action cannot be undone. \n Are you sure you want to delete it?',
                    type: 'warning',
                    callback: () => {

                        // reset file input
                        $id(options.inputId).files = null;
                        $id(options.inputId).value = null;
                        // remove thumb
                        var thumbImg = document.querySelector('#' + options.zoneId + ' .mzdnd_img_thumb');
                        var thumbVideo = document.querySelector('#' + options.zoneId + ' .mzdnd_video_thumb');
                        var thumbZip = document.querySelector('#' + options.zoneId + ' .mzdnd_zip_thumb');
                        if (thumbImg) thumbImg.remove();
                        if (thumbVideo) thumbVideo.remove();
                        if (thumbZip) thumbZip.remove();
                        // remove close button
                        el.remove();
                        // show message
                        if (options.message) _toggleMessage(true);

                        if (options.onClose && typeof options.onClose === 'function') {
                            options.onClose();
                        }
                        _toggleDragZoneClass(true);
                    }
                });


            });
        }

        function _toggleMessage(show) {
            if (!options.message) return;
            var el = document.querySelector('#' + options.zoneId + ' .mzdnd_message');
            if (el && show) el.style.display = 'flex';
            else if (el && !show) el.style.display = 'none';
        }

        function _doVideoProcess(file) {
            // hide message
            _toggleMessage(false);

            // make thumb
            $id(options.zoneId).insertAdjacentHTML('beforeend', '<img class="mzdnd_video_thumb" src="' + options.videoIcon + '" style="width: ' + $('#' + options.zoneId).width() * 0.4 + 'px"/>');

            // make close btn
            _makeCloseBtn();
            _toggleDragZoneClass(false);
        }

        function _addFileFromInput(file) {
            var a = $id(options.inputId);
            a.files = file;
        }
    };

    window.MZDnD = DnD;
})(window);
