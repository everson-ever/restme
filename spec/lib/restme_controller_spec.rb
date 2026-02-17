# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RestmeController", type: :controller do
  let(:products_controller) do
    ProductsController.new(**controller_arguments)
  end

  let(:establishments_controller) do
    EstablishmentsController.new(**controller_arguments)
  end

  let(:settings_controller) do
    SettingsController.new(**controller_arguments)
  end

  let(:controller_arguments) do
    {
      params: controller_params,
      request: request,
      current_user: current_user,
      logged_user: current_user
    }
  end

  let(:controller_params) { {} }

  let(:request) do
    RequestMock.new(query_parameters: query_parameters)
  end

  let(:current_user) do
    User.create(name: "Restme", role: user_role, user_role: user_role, establishment_id: establishment.id)
  end

  let(:user_role) { :client }

  let(:query_parameters) { {} }

  let(:product_a) { Product.create(name: "Bar", code: "ABC", establishment_id: establishment.id) }
  let(:product_b) { Product.create(name: "Foo", code: "DEF", establishment_id: establishment.id) }
  let(:product_c) { Product.create(name: "BarBar", code: "GHI", establishment_id: establishment.id) }
  let(:product_d) { Product.create(name: "FooFoo", code: "JKL", establishment_id: establishment2.id) }

  let(:establishment) { Establishment.create(name: "Foo") }
  let(:establishment2) { Establishment.create(name: "Bar") }

  describe "restme config" do
    context "with current_user_variable" do
      before do
        Restme.configure do |config|
          config.current_user_variable = :logged_user
        end
      end

      let(:expected_result) do
        { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }.as_json
      end

      it "rreturns success response" do
        expect(products_controller.index[:body]).to eq(expected_result)
      end

      it "returns success status" do
        expect(products_controller.index[:status]).to eq(:ok)
      end
    end

    context "with user_role_field" do
      before do
        Restme.configure do |config|
          config.user_role_field = :user_role
        end
      end

      let(:expected_result) do
        { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }.as_json
      end

      it "rreturns success response" do
        expect(products_controller.index[:body]).to eq(expected_result)
      end

      it "returns success status" do
        expect(products_controller.index[:status]).to eq(:ok)
      end
    end

    context "with pagination_default_page" do
      before do
        Restme.configure do |config|
          config.pagination_default_page = 10
        end
      end

      after do
        Restme.configure do |config|
          config.pagination_default_page = 1
        end
      end

      let(:expected_result) do
        { objects: [], pagination: { page: 10, pages: 0, total_items: 0 } }.as_json
      end

      it "rreturns success response" do
        expect(products_controller.index[:body]).to eq(expected_result)
      end

      it "returns success status" do
        expect(products_controller.index[:status]).to eq(:ok)
      end
    end

    context "with pagination_max_per_page" do
      before do
        Restme.configure do |config|
          config.pagination_max_per_page = 10
        end
      end

      after do
        Restme.configure do |config|
          config.pagination_max_per_page = 100
        end
      end

      let(:query_parameters) do
        {
          per_page: 11
        }
      end

      let(:expected_result) do
        [{ body: { per_page_max_value: 10 }, message: "Invalid per page value" }].as_json
      end

      it "rreturns success response" do
        expect(products_controller.index[:body]).to eq(expected_result)
      end

      it "returns success status" do
        expect(products_controller.index[:status]).to eq(:bad_request)
      end
    end

    context "with pagination_default_per_page" do
      before do
        Restme.configure do |config|
          config.pagination_default_per_page = 2
        end

        product_a
        product_b
        product_c
      end

      after do
        Restme.configure do |config|
          config.pagination_default_per_page = 12
        end
      end

      let(:query_parameters) do
        {
          fields_select: "id"
        }
      end

      let(:expected_result) do
        { objects: [{ id: 1 }, { id: 2 }], pagination: { page: 1, pages: 2, total_items: 3 } }.as_json
      end

      it "rreturns success response" do
        expect(products_controller.index[:body]).to eq(expected_result)
      end

      it "returns success status" do
        expect(products_controller.index[:status]).to eq(:ok)
      end
    end
  end

  describe "authorize rules" do
    context "when controller have current_user" do
      context "when user_role_field is a single string" do
        context "when authorize rules class exists" do
          context "when user can access controller action" do
            context "when is super_admin" do
              let(:user_role) { :super_admin }

              let(:expected_result) do
                { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }.as_json
              end

              it "rreturns success response" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "when is other authorized user" do
              let(:expected_result) do
                { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }.as_json
              end

              it "returns success response" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when user can not access controller action" do
            let(:user_role) { :other_role }

            let(:expected_result) do
              [{ body: {}, message: "Action not allowed" }].as_json
            end

            it "returns forbidden response" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end

            it "returns forbidden status" do
              expect(products_controller.index[:status]).to eq(:forbidden)
            end
          end
        end
      end

      context "when user_role_field is with multiple roles" do
        before do
          Restme.configure do |config|
            config.user_role_field = :roles
          end
        end

        after do
          Restme.configure do |config|
            config.user_role_field = :role
          end
        end

        context "when authorize rules class exists" do
          context "when user can access controller action" do
            before do
              product_a
              product_b
              product_c
              product_d
            end

            let(:query_parameters) do
              {
                fields_select: "id",
                id_sort: :asc
              }
            end

            context "when is manager/super_admin" do
              before do
                current_user.roles = %w[manager super_admin]
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id },
                    { id: product_b.id },
                    { id: product_c.id },
                    { id: product_d.id }
                  ],
                  pagination: { page: 1, pages: 1, total_items: 4 }
                }.as_json
              end

              let(:expected_queries) do
                [
                  "SELECT DISTINCT \"products\".\"id\" FROM \"products\" ORDER BY \"products\".\"id\" " \
                  "ASC LIMIT $1 OFFSET $2", "SELECT COUNT(DISTINCT \"products\".\"id\") FROM \"products\""
                ]
              end

              it "returns success response" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end

              it do
                expect { products_controller.index }.to execute_queries(expected_queries)
              end
            end

            context "when is other authorized user" do
              before do
                current_user.roles = %w[manager]
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id },
                    { id: product_b.id },
                    { id: product_c.id }
                  ],
                  pagination: { page: 1, pages: 1, total_items: 3 }
                }.as_json
              end

              it "returns success response" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when user can not access controller action" do
            before do
              current_user.roles = %i[moderator comum]
            end

            let(:expected_result) do
              [{ body: {}, message: "Action not allowed" }].as_json
            end

            it "returns forbidden response" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end

            it "returns forbidden status" do
              expect(products_controller.index[:status]).to eq(:forbidden)
            end
          end
        end
      end

      context "when authorize rules class does not exists" do
        context "when authorize rules does not exists" do
          let(:expected_result) do
            [{ body: {}, message: "Action not allowed" }].as_json
          end

          it "returns forbidden response" do
            expect(settings_controller.index[:body]).to eq(expected_result)
          end

          it "returns forbidden status" do
            expect(settings_controller.index[:status]).to eq(:forbidden)
          end
        end
      end
    end

    context "when controller does not have current_user" do
      let(:current_user) { nil }

      context "when is super_admin" do
        let(:expected_result) do
          { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }
        end

        it "returns success response" do
          expect(products_controller.index[:body]).to eq(expected_result.as_json)
        end

        it "returns success status" do
          expect(products_controller.index[:status]).to eq(:ok)
        end
      end

      context "when is other role" do
        let(:expected_result) do
          { objects: [], pagination: { page: 1, pages: 0, total_items: 0 } }
        end

        it "returns success response" do
          expect(products_controller.index[:body]).to eq(expected_result.as_json)
        end

        it "returns success status" do
          expect(products_controller.index[:status]).to eq(:ok)
        end
      end
    end
  end

  describe "scope rules" do
    describe "index (list many)" do
      before do
        Timecop.freeze(2025, 5, 12)

        product_a
        product_b
      end

      after do
        Timecop.return
      end

      context "when get products without any params" do
        let(:expected_result) do
          {
            objects: [
              {
                id: product_a.id,
                name: "Bar",
                code: "ABC",
                establishment_id: establishment.id,
                created_at: "2025-05-12T00:00:00.000Z",
                updated_at: "2025-05-12T00:00:00.000Z"
              },
              {
                id: product_b.id,
                name: "Foo",
                code: "DEF",
                establishment_id: establishment.id,
                created_at: "2025-05-12T00:00:00.000Z",
                updated_at: "2025-05-12T00:00:00.000Z"
              }
            ],
            pagination: { page: 1, pages: 1, total_items: 2 }
          }.as_json
        end

        it "returns products" do
          expect(products_controller.index[:body]).to eq(expected_result)
        end

        it "returns ok status" do
          expect(products_controller.index[:status]).to eq(:ok)
        end
      end

      context "with field selections" do
        context "with fields_select" do
          context "when passed fields are allowed to select" do
            before do
              ProductsController::Field::Rules.const_set(
                :MODEL_FIELDS_SELECT,
                %i[id establishment_id]
              )

              ProductsController::Field::Rules.const_set(
                :UNALLOWED_MODEL_FIELDS_SELECT,
                %i[code]
              )
            end

            after do
              ProductsController::Field::Rules.send(:remove_const, :MODEL_FIELDS_SELECT)
              ProductsController::Field::Rules.send(:remove_const, :UNALLOWED_MODEL_FIELDS_SELECT)
            end

            let(:query_parameters) do
              {
                fields_select: "id,name,code",
                id_sort: :asc
              }
            end

            let(:expected_result) do
              {
                objects: [
                  {
                    id: product_a.id,
                    name: "Bar",
                    establishment_id: establishment.id
                  },
                  {
                    id: product_b.id,
                    name: "Foo",
                    establishment_id: establishment.id
                  }
                ],
                pagination: { page: 1, pages: 1, total_items: 2 }
              }.as_json
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end

            it "returns ok status" do
              expect(products_controller.index[:status]).to eq(:ok)
            end
          end

          context "when have fields not allowed to select" do
            let(:query_parameters) do
              {
                fields_select: "id,invalid_field"
              }
            end

            let(:expected_result) do
              [{ body: ["invalid_field"], message: "Selected not allowed fields" }]
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result.as_json)
            end

            it "returns ok status" do
              expect(products_controller.index[:status]).to eq(:bad_request)
            end
          end
        end

        context "with defined_fields_select" do
          before do
            ProductsController::Field::Rules.const_set(
              :MODEL_FIELDS_SELECT,
              %i[id establishment_id]
            )
          end

          after do
            ProductsController::Field::Rules.send(:remove_const, :MODEL_FIELDS_SELECT)
          end

          let(:query_parameters) do
            {
              nested_fields_select: "establishment",
              id_sort: :asc
            }
          end

          let(:expected_result) do
            {
              objects: [
                {
                  id: product_a.id,
                  establishment_id: establishment.id,
                  establishment: {
                    id: establishment.id,
                    name: "Foo",
                    setting_id: nil,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z"
                  }
                },
                {
                  id: product_b.id,
                  establishment_id: establishment.id,
                  establishment: {
                    id: establishment.id,
                    name: "Foo",
                    setting_id: nil,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z"
                  }
                }
              ],
              pagination: { page: 1, pages: 1, total_items: 2 }
            }.as_json
          end

          it "returns products" do
            expect(products_controller.index[:body]).to eq(expected_result)
          end
        end

        context "with _nested_fields_select" do
          context "when passed fields are allowed to select" do
            let(:query_parameters) do
              {
                nested_fields_select: "establishment",
                id_sort: :asc
              }
            end

            let(:expected_result) do
              {
                objects: [
                  {
                    id: product_a.id,
                    name: "Bar",
                    code: "ABC",
                    establishment_id: establishment.id,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z",
                    establishment: {
                      id: establishment.id,
                      name: "Foo",
                      setting_id: nil,
                      created_at: "2025-05-12T00:00:00.000Z",
                      updated_at: "2025-05-12T00:00:00.000Z"
                    }
                  },
                  {
                    id: product_b.id,
                    name: "Foo",
                    code: "DEF",
                    establishment_id: establishment.id,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z",
                    establishment: {
                      id: establishment.id,
                      name: "Foo",
                      setting_id: nil,
                      created_at: "2025-05-12T00:00:00.000Z",
                      updated_at: "2025-05-12T00:00:00.000Z"
                    }
                  }
                ],
                pagination: { page: 1, pages: 1, total_items: 2 }
              }.as_json
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end

            it "returns ok status" do
              expect(products_controller.index[:status]).to eq(:ok)
            end
          end

          context "when have nested_fields not allowed to select" do
            let(:query_parameters) do
              {
                nested_fields_select: "user"
              }
            end

            let(:expected_result) do
              [{ body: ["user"], message: "Selected not allowed fields" }]
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result.as_json)
            end

            it "returns ok status" do
              expect(products_controller.index[:status]).to eq(:bad_request)
            end
          end

          context "with has_many/belongs_to association" do
            let(:product_d) { Product.create(name: "Bar", code: "ABC", establishment_id: establishment.id) }
            let(:product_e) { Product.create(name: "Bar", code: "ABC", establishment_id: establishment_two.id) }
            let(:product_f) { Product.create(name: "Foo", code: "DEF", establishment_id: establishment_two.id) }

            let(:establishment_two) { Establishment.create(name: "Bar", setting_id: setting.id) }

            let(:setting) { Setting.create(name: :any) }

            let(:controller_params) do
              {
                id_in: "#{establishment.id},#{establishment_two.id}",
                per_page: 3
              }
            end

            let(:query_parameters) do
              {
                nested_fields_select: "setting,products",
                id_sort: :asc
              }
            end

            let(:expected_result) do
              {
                objects: [
                  {
                    id: establishment.id,
                    name: "Foo",
                    setting_id: nil,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z",
                    products: [
                      {
                        id: product_a.id,
                        name: "Bar",
                        code: "ABC",
                        establishment_id: establishment.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      },
                      {
                        id: product_b.id,
                        name: "Foo",
                        code: "DEF",
                        establishment_id: establishment.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      },
                      {
                        id: product_c.id,
                        name: "BarBar",
                        code: "GHI",
                        establishment_id: establishment.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      },
                      {
                        id: product_d.id,
                        name: "Bar",
                        code: "ABC",
                        establishment_id: establishment.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      }
                    ]
                  },
                  {
                    id: establishment_two.id,
                    name: "Bar",
                    setting_id: setting.id,
                    setting: {
                      id: setting.id,
                      name: "any",
                      created_at: "2025-05-12T00:00:00.000Z",
                      updated_at: "2025-05-12T00:00:00.000Z"
                    },
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z",
                    products: [
                      {
                        id: product_e.id,
                        name: "Bar",
                        code: "ABC",
                        establishment_id: establishment_two.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      },
                      {
                        id: product_f.id,
                        name: "Foo",
                        code: "DEF",
                        establishment_id: establishment_two.id,
                        created_at: "2025-05-12T00:00:00.000Z",
                        updated_at: "2025-05-12T00:00:00.000Z"
                      }
                    ]
                  }
                ],
                pagination: {
                  page: 1,
                  pages: 1,
                  total_items: 2
                }
              }.as_json
            end

            let(:expected_queries) do
              [
                "SELECT \"establishments\".\"id\", \"establishments\".\"name\", " \
                "\"establishments\".\"setting_id\", " \
                "\"establishments\".\"created_at\", \"establishments\".\"updated_at\" FROM \"establishments\" " \
                "ORDER BY \"establishments\".\"id\" ASC LIMIT $1 OFFSET $2",
                "SELECT \"settings\".* FROM \"settings\" WHERE \"settings\".\"id\" = $1",
                "SELECT \"products\".* FROM \"products\" WHERE \"products\".\"establishment_id\" IN ($1, $2)",
                "SELECT COUNT(*) FROM \"establishments\""
              ]
            end

            before do
              product_a
              product_b
              product_c
              product_d
              product_e
              product_f
            end

            it "returns products" do
              expect(establishments_controller.index[:body]).to eq(expected_result)
            end

            it "returns ok status" do
              expect(establishments_controller.index[:status]).to eq(:ok)
            end

            it do
              expect { establishments_controller.index }.to execute_queries(expected_queries)
            end
          end

          context "when select nested_field without select foreign key" do
            let(:query_parameters) do
              {
                fields_select: "id",
                nested_fields_select: "establishment",
                id_sort: :asc
              }
            end

            let(:expected_result) do
              [{ body: ["id"], message: "missing attribute 'establishment_id' for Product" }]
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result.as_json)
            end

            it "returns ok status" do
              expect(products_controller.index[:status]).to eq(:bad_request)
            end
          end
        end
      end

      context "with sort" do
        context "when sort ASC" do
          context "with valid field" do
            context "with id field" do
              let(:query_parameters) do
                {
                  id_sort: :asc,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end
            end

            context "with name field" do
              let(:query_parameters) do
                {
                  name_sort: :asc,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end
            end
          end

          context "with invalid field" do
            let(:query_parameters) do
              {
                updated_at_sort: :asc
              }
            end

            let(:expected_result) do
              [{ body: ["updated_at"], message: "Unknown Sort" }].as_json
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end
          end
        end

        context "when sort DESC" do
          context "with valid field" do
            context "with id field" do
              let(:query_parameters) do
                {
                  id_sort: :desc,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_b.id, name: "Foo" },
                    { id: product_a.id, name: "Bar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end
            end

            context "with name field" do
              let(:query_parameters) do
                {
                  name_sort: :desc,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_b.id, name: "Foo" },
                    { id: product_a.id, name: "Bar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end
            end
          end

          context "with invalid field" do
            let(:query_parameters) do
              {
                updated_at_sort: :desc
              }
            end

            let(:expected_result) do
              [{ body: ["updated_at"], message: "Unknown Sort" }].as_json
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end
          end
        end
      end

      context "with filter" do
        context "with EQUAL filter" do
          context "when field is allowed to filter" do
            context "with name_equal" do
              let(:query_parameters) do
                {
                  name_equal: product_a.name,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 1
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with id_equal" do
              let(:query_parameters) do
                {
                  id_equal: product_a.id,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 1
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with code_equal" do
              let(:query_parameters) do
                {
                  code_equal: product_a.code,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["code_equal"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with LIKE filter" do
          context "when field is allowed to filter" do
            context "with name_like" do
              before do
                product_c
              end

              let(:query_parameters) do
                {
                  name_like: product_a.name,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_c.id, name: "BarBar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with code_like" do
              let(:query_parameters) do
                {
                  code_like: product_a.code,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["code_like"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with IN filter" do
          context "when field is allowed to filter" do
            context "with establishment_id_in" do
              let(:query_parameters) do
                {
                  establishment_id_in: establishment.id.to_s,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with code_in" do
              let(:query_parameters) do
                {
                  code_in: product_a.code,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["code_in"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with BIGGER THAN filter" do
          context "when field is allowed to filter" do
            context "with created_at" do
              let(:query_parameters) do
                {
                  created_at_bigger_than: Time.current - 1.hours,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with name" do
              let(:query_parameters) do
                {
                  name_bigger_than: product_a.name,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 1
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with id" do
              let(:query_parameters) do
                {
                  id_bigger_than: 0,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with updated_at_bigger_than" do
              let(:query_parameters) do
                {
                  updated_at_bigger_than: Time.current,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["updated_at_bigger_than"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with BIGGER THAN OR EQUAL TO filter" do
          context "when field is allowed to filter" do
            context "with created_at" do
              let(:query_parameters) do
                {
                  created_at_bigger_than_or_equal_to: Time.current,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with name" do
              let(:query_parameters) do
                {
                  name_bigger_than_or_equal_to: product_a.name,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with id" do
              let(:query_parameters) do
                {
                  id_bigger_than_or_equal_to: 1,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with updated_at_bigger_than_or_equal_to" do
              let(:query_parameters) do
                {
                  updated_at_bigger_than_or_equal_to: Time.current,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["updated_at_bigger_than_or_equal_to"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with LESS THAN filter" do
          context "when field is allowed to filter" do
            context "with created_at" do
              let(:query_parameters) do
                {
                  created_at_less_than: Time.current + 1.hours,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with name" do
              let(:query_parameters) do
                {
                  name_less_than: product_a.name,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [],
                  pagination: {
                    page: 1,
                    pages: 0,
                    total_items: 0
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with id" do
              let(:query_parameters) do
                {
                  id_less_than: product_b.id + 1,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with updated_at_less_than" do
              let(:query_parameters) do
                {
                  updated_at_less_than: Time.current,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["updated_at_less_than"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end

        context "with LESS THAN OR EQUAL TO filter" do
          context "when field is allowed to filter" do
            context "with created_at" do
              let(:query_parameters) do
                {
                  created_at_less_than_or_equal_to: Time.current + 1.hours,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with name" do
              let(:query_parameters) do
                {
                  name_less_than_or_equal_to: product_a.name,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 1
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end

            context "with id" do
              let(:query_parameters) do
                {
                  id_less_than_or_equal_to: product_b.id,
                  fields_select: "id,name",
                  id_sort: :asc
                }
              end

              let(:expected_result) do
                {
                  objects: [
                    { id: product_a.id, name: "Bar" },
                    { id: product_b.id, name: "Foo" }
                  ],
                  pagination: {
                    page: 1,
                    pages: 1,
                    total_items: 2
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns success status" do
                expect(products_controller.index[:status]).to eq(:ok)
              end
            end
          end

          context "when field is not allowed to filter" do
            context "with updated_at_less_than_or_equal_to" do
              let(:query_parameters) do
                {
                  updated_at_less_than_or_equal_to: Time.current,
                  fields_select: "id,name"
                }
              end

              let(:expected_result) do
                [{
                  body: ["updated_at_less_than_or_equal_to"],
                  message: "Unknown Filter Fields"
                }].as_json
              end

              it "returns products" do
                expect(products_controller.index[:body]).to eq(expected_result)
              end

              it "returns bad request error" do
                expect(products_controller.index[:status]).to eq(:bad_request)
              end
            end
          end
        end
      end

      context "with many scope errors" do
        context "when field is not allowed to filter" do
          context "with code_equal" do
            let(:query_parameters) do
              {
                code_equal: product_a.code,
                fields_select: "id,name",
                updated_at_sort: "DESC"
              }
            end

            let(:expected_result) do
              [
                {
                  body: ["updated_at"],
                  message: "Unknown Sort"
                },
                {
                  body: ["code_equal"],
                  message: "Unknown Filter Fields"
                }
              ].as_json
            end

            it "returns products" do
              expect(products_controller.index[:body]).to eq(expected_result)
            end

            it "returns bad request error" do
              expect(products_controller.index[:status]).to eq(:bad_request)
            end
          end
        end
      end
    end

    describe "show (list one)" do
      before do
        Timecop.freeze(2025, 5, 12)

        product_a
        product_b
      end

      after do
        Timecop.return
      end

      context "when get product without any params" do
        let(:controller_params) do
          {
            id: product_a.id
          }
        end

        let(:expected_result) do
          {
            id: product_a.id,
            name: "Bar",
            code: "ABC",
            establishment_id: establishment.id,
            created_at: "2025-05-12T00:00:00.000Z",
            updated_at: "2025-05-12T00:00:00.000Z"
          }.as_json
        end

        it "returns products" do
          expect(products_controller.show[:body]).to eq(expected_result)
        end

        it "returns ok status" do
          expect(products_controller.show[:status]).to eq(:ok)
        end
      end

      context "with field selections" do
        context "with fields_select" do
          context "when passed fields are allowed to select" do
            let(:controller_params) do
              {
                id: product_a.id
              }
            end

            let(:query_parameters) do
              {
                fields_select: "id,name"
              }
            end

            let(:expected_result) do
              {
                id: product_a.id,
                name: "Bar"
              }.as_json
            end

            it "returns products" do
              expect(products_controller.show[:body]).to eq(expected_result)
            end

            it "returns ok status" do
              expect(products_controller.show[:status]).to eq(:ok)
            end
          end

          context "when have fields not allowed to select" do
            let(:controller_params) do
              {
                id: product_a.id
              }
            end

            let(:query_parameters) do
              {
                fields_select: "id,invalid_field"
              }
            end

            let(:expected_result) do
              [{ body: ["invalid_field"], message: "Selected not allowed fields" }]
            end

            it "returns products" do
              expect(products_controller.show[:body]).to eq(expected_result.as_json)
            end

            it "returns ok status" do
              expect(products_controller.show[:status]).to eq(:bad_request)
            end
          end
        end

        context "with nested_fields_select" do
          context "when passed fields are allowed to select" do
            context "when nested_field have value associated" do
              let(:controller_params) do
                {
                  id: product_a.id
                }
              end

              let(:query_parameters) do
                {
                  nested_fields_select: "establishment"
                }
              end

              let(:expected_result) do
                {
                  id: product_a.id,
                  name: "Bar",
                  code: "ABC",
                  establishment_id: establishment.id,
                  created_at: "2025-05-12T00:00:00.000Z",
                  updated_at: "2025-05-12T00:00:00.000Z",
                  establishment: {
                    id: establishment.id,
                    name: "Foo",
                    setting_id: nil,
                    created_at: "2025-05-12T00:00:00.000Z",
                    updated_at: "2025-05-12T00:00:00.000Z"
                  }
                }.as_json
              end

              it "returns products" do
                expect(products_controller.show[:body]).to eq(expected_result)
              end

              it "returns ok status" do
                expect(products_controller.show[:status]).to eq(:ok)
              end
            end

            context "when nested_field does not have value associated" do
              let(:controller_params) do
                {
                  id: establishment.id
                }
              end

              let(:query_parameters) do
                {
                  nested_fields_select: "setting"
                }
              end

              let(:expected_result) do
                {
                  id: establishment.id,
                  name: "Foo",
                  setting_id: nil,
                  created_at: "2025-05-12T00:00:00.000Z",
                  updated_at: "2025-05-12T00:00:00.000Z"
                }.as_json
              end

              it "returns products" do
                expect(establishments_controller.show[:body]).to eq(expected_result)
              end

              it "returns ok status" do
                expect(establishments_controller.show[:status]).to eq(:ok)
              end
            end

            context "when select nested_field without select foreign key" do
              let(:controller_params) do
                {
                  id: product_a.id
                }
              end

              let(:query_parameters) do
                {
                  fields_select: "id",
                  nested_fields_select: "establishment"
                }
              end

              let(:expected_result) do
                [{ body: ["id"], message: "missing attribute 'establishment_id' for Product" }]
              end

              it "returns products" do
                expect(products_controller.show[:body]).to eq(expected_result.as_json)
              end

              it "returns ok status" do
                expect(products_controller.show[:status]).to eq(:bad_request)
              end
            end
          end

          context "when have nested_fields not allowed to select" do
            let(:controller_params) do
              {
                id: product_a.id
              }
            end

            let(:query_parameters) do
              {
                nested_fields_select: "user"
              }
            end

            let(:expected_result) do
              [{ body: ["user"], message: "Selected not allowed fields" }]
            end

            it "returns products" do
              expect(products_controller.show[:body]).to eq(expected_result.as_json)
            end

            it "returns ok status" do
              expect(products_controller.show[:status]).to eq(:bad_request)
            end
          end
        end
      end

      context "when product id does not exists" do
        let(:controller_params) do
          {
            id: 10_000
          }
        end

        let(:expected_result) do
          [{
            body: {
              id: 10_000
            },
            message: "Record not found"
          }].as_json
        end

        it "returns products" do
          expect(products_controller.show[:body]).to eq(expected_result)
        end

        it "returns not_found status" do
          expect(products_controller.show[:status]).to eq(:not_found)
        end
      end
    end
  end
end
