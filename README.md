# AWS Lambda Monorepo Starter Template

This template uses npm workspace and <a href="https://nx.dev" target="_blank" rel="noreferrer">NX</a> for finding out what packages changed between two git branches at build time.

Repo has two lambdas (Service A and Service B) and a library (logger library) that can be add into any lambda's package.json dependency list (`"dependencies": { "lib-logger": "*" }`). Service B depends on the logger library.

(Note that the package.json `name` field is used to identify the package name in the "dependencies" map. Hence I have set the package.json `name` field of each package to be same as the directory of the package, as a convention to avoid confusion.)

On the `release` branch, I made some changes to the logger library to see how we could make the build figure out which lambdas got affected. (It should only affect Service B)

`git checkout release` and run `./build-scripts/print-affected.sh` to print out only the changed / affected lambdas between release and main branches. Also can run the example `npm run test` command to see that only the affected repo's tests are run. You can run all tests by running the example `npm run test:all` command.

Check the `build-scripts/deploy.sh` for deploying a single lambda.

You need to read about:
- NPM Workspaces
- `nx affected` command