## ![Importful](app/assets/images/logo.svg)

Greetings! :wave:

You’ve likely arrived here after applying for our [Senior Ruby on Rails Developer position](https://job-boards.eu.greenhouse.io/saasgroup/jobs/4493905101) and successfully completing our technical interview. Congratulations on reaching this stage!

## The Challenge

As our clients integrate their affiliate marketing campaigns into our platform, they often send us CSV files containing their existing data for import into our application.

Our research indicates that this capability is what truly sets us apart in our market segment, and we believe CSVs are the future of data exchange. Therefore, we have decided to pivot our business focus to become the leading affiliate data importer in the industry, rebranding ourselves as **Importful**.

To support this initiative, we invite you to assist us in developing our MVP and providing our customers with the best affiliate CSV importer available.

### The Data Model

For our MVP, we have streamlined our data model to include just two components: [`Merchant`](./app/models/merchant.rb)s (our clients who create and manage marketing campaigns) and [`Affiliate`](./app/models/affiliate.rb)s (who drive traffic to the merchants' stores and earn commissions on sales). Each merchant can have multiple affiliates.

Merchant management is outside the scope of this challenge, and we have already populated the database with roughly a hundred merchants in our [seed file](./db/seeds.rb). Merchants are identified by an internal database ID and an externally visible unique identifier, the `slug` (formatted as a `dash-separated-url-friendly-name`).

Affiliates are required to have several attributes (`first_name`, `last_name`, `email`) and may have optional attributes (`website_url` — defaults to `nil` and `commissions_total` — defaults to 0). Affiliates are uniquely identified by their email addresses, which must be unique per merchant. The data imports will primarily focus on affiliate information.

### The CSV Files

The affiliate CSV files include the following fields for each entry, reflecting our database model:

- `merchant_slug`: External identifier for the merchant
- `first_name`, `last_name`: Affiliate's name
- `email`: Affiliate's email address. Must be unique per merchant
- `website_url`: Affiliate's website. This field may be absent or blank.
- `commissions_total`: Total commissions earned by the affiliate to date. This field may also be absent or blank.

The order of these attributes is not fixed, so the file must include a header with field names.

Since these files are often generated semi-manually by customers, they may exhibit various inconsistencies, such as:

- Unwanted leading or trailing spaces
- Incorrect capitalization (e.g., in email addresses, URLs)
- Number formats that may vary by user locale (e.g., using commas or dots as decimal or thousand separators)
- URLs that may lack protocols
- Use of tabs, semicolons, or colons as delimiters

### The UI

The main view right now features a basic, unstyled upload form, supported by a controller that is yet to be implemented. The asset pipeline is configured for Bootstrap, but you are welcome to utilize any library or UI framework that you believe suits this project best.

At a minimum, the UI should:

- Enable users to upload a CSV file
- Provide appropriate feedback regarding success and error states

It is up to you to determine the user experience and visual design of the UI. The UI should be polished enough to be presented to potential customers in a hypothetical product launch.

### Considerations

- How will errors be handled and communicated to the user when issues arise with the file content? What level of strictness or leniency will the application apply when processing invalid data?
- How does the application perform with large files (hundreds of MB, hundreds of thousands of rows)? What is the memory consumption? How long does the import take, and is it possible to complete it without timing out?
- How will the code be tested and documented?

If you are pressed for time, it is acceptable to develop a solution that does not fully meet all the requirements, provided you document the compromises made and outline what the optimal or improved implementation would have entailed.

## Getting Started

To facilitate your work, this repository already includes the basic structure of a Rails project, complete with some models, tests, and fixtures. Additionally, a straightforward yet realistic CI pipeline has been established using GitHub Actions.

### Create a New Repository

1. Set up a new private repository on your GitHub profile, [using this template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template#creating-a-repository-from-a-template).
2. Avoid committing directly to the `main` branch; instead, create a new feature branch for your changes.

### Set Up the App

1. Install the required versions of [Ruby](./.ruby-version) and [Node.js](./.node-version) using your preferred version manager. You will also need to have Yarn 1.x installed (`npm install -g yarn`).

2. Install the dependencies:

   ```console
   bundle install
   yarn install
   ```

3. Prepare the database:

   ```console
   bin/rails db:setup
   ```

4. Launch the application:

   ```console
   bin/dev
   ```

### Submit the Challenge

1. Open a pull request with your changes against your `main` branch (not this template repository!).

2. Invite [@rewardful-recruiting](https://github.com/rewardful-recruiting) to your repository as a read-only collaborator.

3. Notify us via email when your code is ready for review.
