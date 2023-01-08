# AWS Lambda Monorepo Starter Template

This template uses npm workspace, yarn 1 (for nohoist) and <a href="https://nx.dev" target="_blank" rel="noreferrer">NX</a> for finding out what packages changed between two git branches at build time.

Repo has two lambdas (Service A and Service B) and a library (logger library) that can be add into any lambda's dependency list Service B depends on the logger library.

On the `release` branch, I made some changes to the logger library to see how we could make the build figure out which lambdas got affected. (It should only affect Service B)

`git checkout release` and run `./build-scripts/print-affected.sh` to print out only the changed / affected lambdas between release and main branches. Also can run the example `yarn test` command to see that only the affected repo's tests are run. You can run all tests by running the example `yarn test:all` command.

Check the `build-scripts/deploy.sh` for deploying a single lambda.

You need to read about:
- NPM Workspaces
- Yarn `nohoist` feature
- `nx affected` command

## Notes

Note that all the packages have been added to the `nohoist` list in the `package.json` so that it is easier to isolate a lambda's dependencies before packaging it as a zip for uploading it to AWS lambda (and that's also the reason why `yarn` is used on this template, as npm doesn't give `nohoist` feature). The caveat here is that if a shared library installs the same dependency as the lambda then the zip file would end up having two copies of the same library. To solve this, you have to add the dependency as both peerDependency and devDependency in the shared library package :( (I don't have a nicer solution)