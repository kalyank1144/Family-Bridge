/*
 Monorepo root ESLint flat config.
 Scopes analyzers per subproject to avoid cross-project linting noise.
 Ignored: Flutter (lib, android, ios), Supabase (Deno), and caregiver-dashboard (has its own ESLint).
*/

export default [
  {
    ignores: [
      "lib/**",
      "android/**",
      "ios/**",
      "supabase/**",
      "caregiver-dashboard/**",
    ],
  },
  {
    files: [
      "scripts/**/*.js",
      "web/firebase-messaging-sw.js",
    ],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
    },
    rules: {
      "no-console": "off",
    },
  },
];