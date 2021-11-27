" Integration with vim-visual-multi
aug VMlens
    au!
    au User visual_multi_start lua require('plugin.vmlens').start()
    au User visual_multi_exit lua require('plugin.vmlens').exit()
aug END
