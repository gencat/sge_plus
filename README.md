# sge_plus

Free Open-Source participatory democracy, citizen participation and open government for cities and organizations

This is the open-source repository for SGE+. SGE+ is based on [Decidim](https://github.com/decidim/decidim).

## Development

```bash
bundle install
nvm use 18.17.1
npm install
bin/rails db:create db:schema:load
bin/rails db:seed
bin/dev
```
## Testing

Run `bin/rake decidim:generate_external_test_app` to generate a dummy application to test both the application and the modules.

Require missing factories in `spec/factories.rb`

Add `require "spec_helper"` to your specs and execute them from the root directory, i.e.:

```bash
bundle exec rspec --backtrace
```
