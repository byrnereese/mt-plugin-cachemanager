# Clear Cache Plugin for Movable Type and Melody
# Copyright (C) 2009 Endevver, LLC.

package CacheManager::Plugin;

use strict;
use MT::Util qw( encode_html );

sub itemset_clearcache {
    my $app = shift;
    my $q = $app->{query};
    $app->validate_magic or return $app->error("Invalid magic");
    my @tmpls = $q->param('id');
    for my $tmpl_id (@tmpls) {
        my $tmpl = MT->model('template')->load($tmpl_id) 
	    or return $app->error( "Unable to load template #" . $tmpl_id );
	my $type = $tmpl->type eq 'widget' ? 'widget' : 'custom'; 
	my $cache_key = 'blog::' . $app->blog->id . '::template_' . $type . '::' . $tmpl->name;
	MT->log({ blog_id => $app->blog->id, message => "Clearing cache for " . $tmpl->name });
        require MT::Cache::Negotiate;
        my $cache_driver = MT::Cache::Negotiate->new();
        my $cache_value = $cache_driver->get($cache_key);
	if ($cache_value) {
	    $cache_driver->delete($cache_key);
	}
    }
    $app->call_return( cache_flushed => 1 );	
}

sub itemset_viewcache {
    my $app = shift;
    my $q = $app->{query};
    $app->validate_magic or return $app->error("Invalid magic");
    my @tmpls = $q->param('id');
    for my $tmpl_id (@tmpls) {
        my $tmpl = MT->model('template')->load($tmpl_id) 
	    or return $app->error( "Unable to load template #" . $tmpl_id );
	my $type = $tmpl->type eq 'widget' ? 'widget' : 'custom'; 
	my $cache_key = 'blog::' . $app->blog->id . '::template_' . $type . '::' . $tmpl->name;
        require MT::Cache::Negotiate;
        my $cache_driver = MT::Cache::Negotiate->new();
        my $cache_value = $cache_driver->get($cache_key);
	if ($cache_value) {
	    return encode_html($cache_value);
	}
    }
    return $app->error( 'Nothing in the cache for this module.' );
}

sub xfrm_list {
    my ($cb, $app, $tmpl) = @_;
    if ($app->param('cache_flushed')) {
    my $slug1 = <<END_TMPL;
      <mtapp:statusmsg
          id="cache-flushed"
          class="success">
          <__trans phrase="The cache for the selected templates has been flushed.">
      </mtapp:statusmsg>
END_TMPL
    $$tmpl =~ s{(<mt:setvarblock name="system_msg">)}{$1$slug1}msg;
    }
}

1;
__END__
