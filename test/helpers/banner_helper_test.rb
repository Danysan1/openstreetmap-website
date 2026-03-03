# frozen_string_literal: true

require "test_helper"

class BannerHelperTest < ActionView::TestCase
  def make_banner(id, locales: nil, countries: nil)
    {
      :id => id,
      :alt => "Test Banner",
      :link => "https://example.com",
      :img => "banners/test.png",
      :enddate => "2099-jan-01",
      :locales => locales,
      :countries => countries
    }.compact
  end

  def test_banner_without_locales
    banners = { :global => make_banner("global") }

    stub_const(:BANNERS, banners) do
      I18n.with_locale(:en) do
        result = active_banners
        assert_includes result.keys, :global
      end

      I18n.with_locale(:"zh-TW") do
        result = active_banners
        assert_includes result.keys, :global
      end
    end
  end

  def test_banner_with_single_locale
    banners = { :german => make_banner("german", :locales => %w[de]) }

    stub_const(:BANNERS, banners) do
      I18n.with_locale(:de) do
        result = active_banners
        assert_includes result.keys, :german
      end

      I18n.with_locale(:en) do
        assert_empty active_banners
      end
    end
  end

  def test_banner_with_multiple_locales
    banners = { :regional => make_banner("regional", :locales => %w[it en-GB zh-TW]) }

    stub_const(:BANNERS, banners) do
      I18n.with_locale(:it) do
        assert_includes active_banners.keys, :regional
      end

      I18n.with_locale(:"en-GB") do
        assert_includes active_banners.keys, :regional
      end

      I18n.with_locale(:"zh-TW") do
        assert_includes active_banners.keys, :regional
      end

      I18n.with_locale(:fr) do
        assert_empty active_banners
      end
    end
  end

  def test_mixed_banner_locales
    banners = {
      :global => make_banner("global"),
      :italian => make_banner("italian_only", :locales => %w[it])
    }

    stub_const(:BANNERS, banners) do
      I18n.with_locale(:it) do
        result = active_banners
        assert_includes result.keys, :global
        assert_includes result.keys, :italian
      end

      I18n.with_locale(:en) do
        result = active_banners
        assert_includes result.keys, :global
        assert_not_includes result.keys, :italian
      end
    end
  end

  def test_banner_without_countries
    banners = { :global => make_banner("global") }

    stub_const(:BANNERS, banners) do
      OSM.stub(:ip_to_country, "IT") do
        assert_includes active_banners.keys, :global
      end
    end
  end

  def test_banner_with_single_country
    banners = { :germany => make_banner("germany", :countries => %w[DE]) }

    stub_const(:BANNERS, banners) do
      OSM.stub(:ip_to_country, "DE") do
        assert_includes active_banners.keys, :germany
      end

      OSM.stub(:ip_to_country, "US") do
        assert_empty active_banners
      end
    end
  end

  def test_banner_with_multiple_countries
    banners = { :itde => make_banner("itde", :countries => %w[IT DE]) }

    stub_const(:BANNERS, banners) do
      OSM.stub(:ip_to_country, "IT") do
        assert_includes active_banners.keys, :itde
      end

      OSM.stub(:ip_to_country, "DE") do
        assert_includes active_banners.keys, :itde
      end

      OSM.stub(:ip_to_country, "US") do
        assert_empty active_banners
      end
    end
  end

  def test_mixed_banners_country_filtering
    banners = {
      :global => make_banner("global"),
      :italy => make_banner("italy_only", :countries => %w[IT])
    }

    stub_const(:BANNERS, banners) do
      OSM.stub(:ip_to_country, "IT") do
        result = active_banners
        assert_includes result.keys, :global
        assert_includes result.keys, :italy
      end

      OSM.stub(:ip_to_country, "US") do
        result = active_banners
        assert_includes result.keys, :global
        assert_not_includes result.keys, :italy
      end
    end
  end

  private

  def stub_const(name, value)
    old = Object.const_get(name)
    Object.send(:remove_const, name)
    Object.const_set(name, value)
    yield
  ensure
    Object.send(:remove_const, name)
    Object.const_set(name, old)
  end
end
