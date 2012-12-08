require "spec_helper"

class Product < ActiveRecord::Base
  belongs_to :category
  belongs_to :sub_category
  belongs_to :site
  has_many :line_items
  has_many :sub_line_items
  has_many :baskets, :through => :line_items
  has_many :sub_baskets, :through => :sub_line_items, :source => :basket
  has_many :discounts, :through => :line_items
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :sub_tags, :join_table => 'products_tags', :association_foreign_key => 'tag_id'
  has_one :image
  has_one :sub_image
end

class LineItem < ActiveRecord::Base
  belongs_to :basket
  belongs_to :product
  has_many :discounts
end

class SubLineItem < LineItem; end

class Image < ActiveRecord::Base
  belongs_to :product
end

class SubImage < Image; end

class Discount < ActiveRecord::Base
  belongs_to :line_item
end

class Basket < ActiveRecord::Base; end
class Category < ActiveRecord::Base; end
class Site < ActiveRecord::Base; end
class SubCategory < Category; end
class Tag < ActiveRecord::Base; end
class SubTag < Tag; end

describe ActiveRecord::Base do
  describe ".outer_joins" do
    context "with belongs_to" do
      it "performs an outer join" do
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true
        query = Product.outer_joins(:category).where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product2, product3]
      end

      it "performs an outer join with sti" do
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        subcategory1 = SubCategory.create! :name => "Cool Shoes"
        subcategory2 = SubCategory.create! :name => "Cool Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true, :sub_category => subcategory1
        product4 = Product.create! :category => category1, :sub_category => subcategory2

        query = Product.outer_joins(:category).where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product2, product3]

        query = Product.outer_joins(:sub_category).where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product3]
        query = Product.outer_joins(:sub_category).where("categories.name = ? OR products.published = ?", "Cool Shirts", true)
        query.all.should =~ [product3, product4]
      end

      it "joins several associations" do
        site1 = Site.create! :name => "Elabs"
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true
        product4 = Product.create! :site => site1
        query = Product.outer_joins(:category, :site).where("sites.name = ? OR categories.name = ? OR products.published = ?", "Elabs", "Shirts", true)
        query.all.should =~ [product2, product3, product4]
      end
    end

    context "with has_one" do
      it "performs an outer join" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        Image.create! :highres => true, :product => product1
        Image.create! :product => product2

        query = Product.outer_joins(:image).where("images.highres = ? OR products.published = ?", true, true)
        query.all.should =~ [product1, product3]
      end

      it "performs an outer join with sti" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        Image.create! :highres => true, :product => product1
        Image.create! :product => product2
        SubImage.create! :highres => true, :product => product2
        SubImage.create! :product => product1

        query = Product.outer_joins(:image).where("images.highres = ? OR products.published = ?", true, true)
        query.all.should =~ [product1, product2, product3]

        query = Product.outer_joins(:sub_image).where("images.highres = ? OR products.published = ?", true, true)
        query.all.should =~ [product2, product3]
      end
    end

    context "with has_many" do
      it "performs an outer join" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        LineItem.create! :price => 4, :product => product1
        LineItem.create! :product => product2

        query = Product.outer_joins(:line_items).where("line_items.price = ? OR products.published = ?", 4, true)
        query.all.should =~ [product1, product3]
      end

      it "performs an outer join with sti" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        LineItem.create! :price => 4, :product => product1
        LineItem.create! :product => product2
        SubLineItem.create! :price => 4, :product => product4
        SubLineItem.create! :product => product2

        query = Product.outer_joins(:line_items).where("line_items.price = ? OR products.published = ?", 4, true)
        query.all.should =~ [product1, product3, product4]

        query = Product.outer_joins(:sub_line_items).where("line_items.price = ? OR products.published = ?", 4, true)
        query.all.should =~ [product3, product4]
      end
    end

    context "with has_and_belongs_to_many" do
      it "performs an outer join" do
        red = Tag.create! :name => "Red"
        blue = Tag.create! :name => "Blue"

        product1 = Product.create!
        product2 = Product.create! :tags => [red]
        product3 = Product.create! :tags => [red, blue]
        product4 = Product.create! :published => true


        query = Product.outer_joins(:tags).where("tags.name = ? OR products.published = ?", "Red", true)
        query.all.should =~ [product2, product3, product4]
      end

      it "performs an outer join with sti" do
        red = Tag.create! :name => "Red"
        blue = Tag.create! :name => "Blue"
        green = SubTag.create! :name => "Green"
        black = SubTag.create! :name => "black"

        product1 = Product.create!
        product2 = Product.create! :tags => [red, green]
        product3 = Product.create! :tags => [red, blue, black]
        product4 = Product.create! :published => true


        query = Product.outer_joins(:tags).where("tags.name = ? OR products.published = ?", "Red", true)
        query.all.should =~ [product2, product3, product4]

        query = Product.outer_joins(:sub_tags).where("tags.name = ? OR products.published = ?", "Green", true)
        query.all.should =~ [product2, product4]
      end
    end

    context "with has_many :through" do
      it "performs an outer join" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        basket1 = Basket.create! :purchased => true
        basket2 = Basket.create! :purchased => false

        LineItem.create! :product => product1, :basket => basket1
        LineItem.create! :product => product2, :basket => basket2
        LineItem.create! :product => product3

        query = Product.outer_joins(:baskets).where("baskets.purchased = ? OR products.published = ?", true, true)
        query.all.should =~ [product1, product3]
      end

      it "performs an outer join with sti" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!
        product5 = Product.create!
        product6 = Product.create!

        basket1 = Basket.create! :purchased => true
        basket2 = Basket.create! :purchased => false

        LineItem.create! :product => product1, :basket => basket1
        LineItem.create! :product => product2, :basket => basket2
        LineItem.create! :product => product3
        SubLineItem.create! :product => product4, :basket => basket1
        SubLineItem.create! :product => product5, :basket => basket2
        SubLineItem.create! :product => product6

        query = Product.outer_joins(:baskets).where("baskets.purchased = ? OR products.published = ?", true, true)
        query.all.should =~ [product1, product3, product4]

        query = Product.outer_joins(:sub_baskets).where("baskets.purchased = ? OR products.published = ?", true, true)
        query.all.should =~ [product3, product4]
      end
    end

    context "with nested associations" do
      it "allows hashes" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        basket1 = Basket.create! :purchased => true
        basket2 = Basket.create! :purchased => false

        LineItem.create! :product => product1, :basket => basket1
        LineItem.create! :product => product2, :basket => basket2
        LineItem.create! :product => product3

        query = Product.outer_joins(:line_items => :basket).where("baskets.purchased = ? OR products.published = ?", true, true)
        query.all.should =~ [product1, product3]
      end

      it "allows hashes with arrays" do
        product1 = Product.create!
        product2 = Product.create!
        product3 = Product.create! :published => true
        product4 = Product.create!

        basket1 = Basket.create! :purchased => true
        basket2 = Basket.create! :purchased => false

        line_item1 = LineItem.create! :product => product1, :basket => basket1
        line_item2 = LineItem.create! :product => product2, :basket => basket2
        line_item3 = LineItem.create! :product => product4

        Discount.create! :line_item => line_item3, :percentage => 80

        query = Product.outer_joins(:line_items => [:basket, :discounts]).where("baskets.purchased = ? OR products.published = ? OR discounts.percentage > ?", true, true, 50)
        query.all.should =~ [product1, product3, product4]
      end
    end

    context "with raw hash" do
      it "allows a join as a string" do
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true
        query = Product.outer_joins("LEFT OUTER JOIN categories ON products.category_id = categories.id")
        query = query.where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product2, product3]
      end

      it "allows multiple joins" do
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true
        query = Product.outer_joins(:line_items, "LEFT OUTER JOIN categories ON products.category_id = categories.id")
        query = query.where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product2, product3]
      end

      it "allows arel joins" do
        category1 = Category.create! :name => "Shoes"
        category2 = Category.create! :name => "Shirts"
        product1 = Product.create! :category => category1
        product2 = Product.create! :category => category2
        product3 = Product.create! :published => true

        on = Arel::Nodes::On.new(Product.arel_table[:category_id].eq(Category.arel_table[:id]))
        join = Arel::Nodes::OuterJoin.new(Category.arel_table, on)

        query = Product.outer_joins(join)
        query = query.where("categories.name = ? OR products.published = ?", "Shirts", true)
        query.all.should =~ [product2, product3]
      end
    end
  end
end
