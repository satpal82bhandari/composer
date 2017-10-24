ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh
./fabric-dev-servers/createComposerProfile.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.14.2
docker tag hyperledger/composer-playground:0.14.2 hyperledger/composer-playground:latest


# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d
# copy over pre-imported admin credentials
cd fabric-dev-servers/fabric-scripts/hlfv1/composer/creds
docker exec composer mkdir /home/composer/.composer-credentials
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer-credentials

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� (��Y �=�r9v��d3锓�*�M�	�v���$��&)ʫ�i^EK�ěd��j�n�l�٠�B�Rq+��U���F�!���@^��W�"Y=3&$}pp ���*V���)����uث��1T��?y�"��H�(������1$FC�H4*81B�=����8�M ��&�h�|�e����LK��x|�q2;������	s�|��j2��B;ç�ւuR�赑�#������K1�66m�E	��������CFG3��B�= J�K��y�0��fv��� ���h�h���M����UhC2�AySB��W�2�<�	�!d�jK3��ab]�+!�D6m�?,WJ��f�bc���nCL4�a ݅��a��l�<�)6��#�4-�`Û��^�USS_E�bjm�]~o�a ����a�I������z�P/��d��n�!�C�&���UԠn-�Wk!��e	�8l��$,�t�����c����Vv�]�V[Gt;Q!,�_vZ��b�(��hT-hղ��$msh��\�h��Xl�7��m���������e"2����O��`����Ddٕ���2S��̑.b�!N�!�|[��O杻)�1����7��#�}�@v�MfWTT���Yti#Ӏ���Lڮs���V��W�T��Q�O�4��}P'/���h����@���$1|�NɌ��3��Fč�]õ�~�q�>���篿����`P���G�`d����<�.PՌ@Z�� �?������I5&�|�K{��J1�z'|��`���]�|
��g�0��K�e��S٧��Y�_��e-�_v�!�m�4a�/,l<H��O�{�'���G��E�n:�ޛ��6�c'b���a�v�h�md������Y�9�5l��Z�Mň�i٠�tg���6��)i�� Ve"�\����Ox��mx�,��%ON�nb3�(m�u�O�sަ��������S�k�ҧk
2,ַL���|A�,�&��:���c���Xi*8<��-�;tB-J�o��� �aEc��C
�ٷF�Pu4]�ASih���|>������ZA�{4Z�ɛ� ����?��'�Z_�Js�~ix�>"�=�M=�!-�� ����&���?Yד���}]�%�_�<���AA���_E���g�zy���0�h���� *0Qw�D�tC3꣗B7ldٸ���]sܑ��|Se,��}��xG��#�x����^S�QHi`���(nH������A�0l�;�z`t2�\M#�';����^��t�n�`��F���YL'��{Kfh�."(�3悰9;�A�09o�	w�-"X���"H{L������i`\��e�)����a��Oq6��������3�'!ǟPr�������{�B]��lֈҮb�g7�D�0�Q)���ZXHG��Mi �<�#�9����ɘ|�d#ޛu�ޜ�3~����t�<�~"�ׄ��*��9�eOw����5 U����#������Լ�ـ�F�Хf{�Ȃ
�b�-�Zf��Hv�C���"ᨰ���(��/�̐��Z>PK�_���i��翫)����øޙ{���h���O�z�3��s��͘��:i�iRDk��=.�-�~�:��{��y)Q��w&�	y��gϳ+z;�ϯǀ�/(I�Y�]/7-ǋ���q�X��_^�Gn���N  ��a!�q�-�E;pÆ�%�\�v��"����`�[��'b�N�&���\,�����a�<��	�Y��a�i!�X��uc�wŰ;��h�ş�	�؇��YT!�;��x>���?��&>�ᖄ9�sI�y�C`8�*2y������-"mK�d�@�'t��V�d���|�Sq�qY��f�Or����_!;vr^D�}������]��)k���.3�дr�L�C�0��EC��������٧z}όvhY]>_�D5��8A<$г�k�s�2C�������L����������?WP��?��܋����z�WRn���	
^v�#DCS�
E��%e��o��±A��ed��|ڦf���V����܇:��#���ba'��c"N.&�vv����~^|J���c"���pl�����`�'VϲQ� #B=��s"����_�U��V,�զj��X��3!�V��DJ��;M+P�AR6➙-�3k����̆��+�6�0��S��3��:b�E
V�x�L �_O�s���}�L�N��5�>��EG�X�\��r[����e�?*M���B��[���/����D>R��B��x!"6������Q)�큫��� ����8�^{�a�'���^�w�V�ѹK�������P�M��m��>A��?,E��?��%�����d��-�ްAuH���~�Ox<0���v�n+��y)�4�72-�R4���]I���?���.�!�ݙ>�Rp��Y�f>c�f#� µ��\�k���)�
���6��0Ip�� ������}�P!����4��6z�.zqSwiƳ��LQr�^���l?����&�AxIC���):&�H�+0��gi&/�ČS��ffΘ�}:YƬ��raLu*�����\��0����)�r����C��s}���%3��Ҁ�@Z�"��HuxV2��{5c(�
��͗[������>�~�/F�������?Rb�z�ۗ��������N�����:�s%�����s��7_��o��?�������)���O(TI
ƶk���R֪5Iَ�"�j,(�I"�"R�I
�b�XL�F����v8��_s���F�!o�+�wr��k�!�����WԼm<��9�%�aa�֜��?o��1�`��o�뫍�|5��߿����~�r�Y������n�|�G2d�����l^Mk�O	��+�a��F��x������s��[�.��ýSw��!a��WS>q���&o������RD���*ʵ��O J��J�;�ARz��kd��A7�O��Lm:Y��\�V��lY��{D%��F�5A�n����v����Ĥ`��l�PPB��@q;
cU1
aJR8J�Іخy�Z�V��GK<���A"U,g�ل\N���F.�Md.	YI��n6.׳E9����=5���ۨ�SM��M�O���,{u!�lW�Jr3#��T��K�.SWr1^�T�D3ߨf�V5�Ɓ'���\q�)��1y��3���vN���ip�2S�ߺ����zgW)��m�Q}��J�jP��K�ЅɕS�|�qК	��k(�\Y��/��\9+���Zw��A�{��"^��n�p�<.2����U��#GG������O�:J+�>-�Nr�;��\��Q	��l�wz��o�իT-���N�6<	�d.�\)��L�V2��A+ߩ��gd&�L��1S�I1���$��njO�r<�l�_�b�yY*��A'����\��H���I��&�g4O��z�R;���~�%M�gѳv7��/E�VN=*FΤT/S��_���,�� Ԫ�n*���Փr���^1�k�)�B�s	��J�v�\b_��[�t��l<��0���~�c�E$ M!�������r''����
&d�.�R�D�����B佑H�?V˧HچW��I,�0�^F��0*'��q��P�l�ޏ�V�MO�i�j�T���E��{��qn�
Z/!Ţ5_)ʻ���|r���~��~:�F�@3���c��?��S���9�Q��'����(�obl/�[��WZ>���Ww�hj��=�uY��/�������D1���[I󓎊�cb�~��>�r�����"�]H}�B�.���A|k��֬F�rg��Pߢ|�D�;z:����~�:�r%d�hvV��/�s��U&�/���VB�/��������^���:
W�����h����a�"��w��+����%�rC�ws`�{�9�a����?����(���;��=�uy�˰��Y���s%e��W��ĸ�O7����w���ã��\P�����Ѯ�J'+��~��<�;KDo�mx�
=��a�,�k�����:��b���������A��6�!u�K�^
���Q/gaR����i�>���v�'��mcXR����ů�-�����ﰴ�����$p�g���l<G��m?�ui�������(ˣ�[߁������4d�Q�[G }W6�Ѝ@:4�| �j����)\�Q]�Ю؁�ZЀu��ċZVم��$i���2����:x�>�g?�3��$nA��c�U������R)lK�ځ�"�"wYU5:�K0�H�0RF?F��-��� �w���5�ȶGa�%�ſu�Q���q�tx�c���4Ȗ�����h�I���W�%�w�l�cWc,D#i8+�a����1_��@��]z���K�T�2"�m�ʕF����^ ���	{�CZI�MYw�؀Q]��mi�$jw1 �BW=y{6%q l�GG#ۋ-Pn0�_ؠ(�+`A����E���I�9Æ���Le@}��B�����G�g���TDU��d�my2�xo��b����&�L����__���������>�����J�5����v���L�b��1Q�KRs0��|Ld�)�u���?k�i��կaL괖�(z�fN̯;��'��(��C���Zî|�>�
҅d�e�U3��*4��_=�rH��������^���h���<U�.�@�u"l�0j���<����P�7�DǸI�jM�j��ʻ��x�1l�8`�S����%���G)d�l�F[�ܫ�4_�|m��l���-�7̡�;t�I�T5٦��.~**��5��O�`��Fv��U�tbhR�c;tB�RQt�"RDt�`l��b����T��ɚ��u�)nwtL/W�D\6��i�9Th�]m���`]��tX��9�	�e�q3���M�}��#�!��%�����,]�~�@~~��ĩb��⏅ߛ���R�
���g8'��*��s�x,��(bÝZ�%��O���#�Xh��~�da���������޵�:�������"5��`�P�t��T���I.SR۱�87��y��rb'q�<n��I�X �h	����쐘[�fB��`�;`>Ǐ8����-�9��u�}������?E��^��Q0��������7���ߞ��7?��\1������������}�G��#�7�^�����~��o�[��ń*�Y�
EC�"aR8$G��b-f(i�!<�P$�5�p��b��Q'�-Ec��~!�f�Q��_����r����I��_���:7s_�?z�?���a�w���`�|y{����~���������s����ޣ�|�|M(���0����?=D~�����-�C��b@� ZL�h��n��h���ұ�B꽲ɰ�)��w��\�P`���*��*\���U�iم�Ba7��k	��F`��NpSdwFZI��<��	�W��)���la?+x�!%��K:m#��"�UD�(��=4�3�l�:7�Es�u�b�L��]�3q�B�S���Av�"�3��7&�p��k��yfP	׫��L��u"fE�Lv`���^�D��x��j�_ p�ΰ�~_?旧�3�3�]4��\�4L�>�O���ev��bЉ\�P-���M��L$��~nΔd�LYɮ�m	�dA7�X�.�P��־�t"����t=�0	�m�&�,ڙ�&�gKz!g�0�w
��dh��������t>@i���Ԭ��F�L}�ow���M�"[��,�|'���P��3���u�Ǣ�<V3ejr����b���̴�5�U&)iV-��"�F�ٸI���џ��cE�B[�V��:��b��x%7�{��z��y��x��w��v��u��t��s��r��q��\^�̻ț�M�?I*�W2J�j��S;ܬ&���[�T6���b|��V;Ľ��΅���/�{�z�PH�o�z�{n�z�f�j ���7�f�v�q�O��^��+&#�ih����j�Q˭�B�%�Q��"�rS&tB��i���*O�e)�(����&81�#�M����ꟛ��HcD���t,�IH��eg�Z�еp*'ѽ���"2O��n�ܼP�d��,��ȔK�(��i�t�̚�a�ډ�2d��8ُ�t-�g��M�	�K�N+*Un�s�V��6+���v|0�R�.�.l��ůo~�������[ֿo���mp{˱������K��ƮW»!��^ܾ�|ks�ijk�$����Gn�}�:�P�{��tыǿ�;8���f���k^.*��@o���>��7�G��O��臎��'�����{��ϯe��%�di��y#:ˉ����"�E�5Jn��t�$�h��`钫���&߷̄-XX�$�CɅ��j,��J.�6V�_r!��*�\�]��)�kSv%p_��� �*�"�i9ʂgV�C`�1!�(�
�O�"S*N���q^I�
H�ʇ��S96����7�cu���i�E��ASi��i�aZ����� ���8]�Q��tΖ2Q��Z��DҬ�4�N���,����Ha�B�8���T&�HMn9P��t��<�W�#CJ��-	4_��Diԭ�|���O�5E�ɦh��h�Vkʢ��%���-�Z$ܯ�,���M���e��XFHGh�1��6�v���k�qc6�T�^:��xA+����/��֕L�r�3��4���AA�f2\4��;�nq����/\���w�f�@N,�k ��l�Տ��UL�Ɗ\H`�l�[d��"���g��������q��-���@�Gם�Y�_�߬j�B�z*�o!��в'�ZM�YG��<QO��4[i��ᰤd3�q���c��L��0�3��0��F�6W�>O�j��GY�*�ϳY��w�p�h�6�9�P�4m����c��ѝ�`.��N!�;��|�����H�{~j��V!��9_�ēiaKU��
��K���U��d���SվX��\���&��́t��ԼX-��b8�L%��xJ��n���b]���p��rM/�nd��<��"Y����
�aM�L<�d������W���$�(�yµ5�G0B҄�����L��|�2��혫L���w
���^�PJ�a�P��N��c��Jyɓ�Zu��&\돹�N��Dt�(���-��1.it�TϢ$cd�,��ˣJ7Җ��LE���h��*��(;J�����c�p>\�����Y�gh�@�b�b'H_
)qC�z
�!��e�N8M��)Nʕ*��Z-6�ӳ�R�G�ck�ɨeTb�Ҽ�M�A�jn�X�Cٰ��V5VʱZ����<�4��K5�-�|�K���7ݼB�g7^�Lhe2_��g��бE��nLT��X����藑����P���b��B��G�����F2Zݒ�T��>B<������[�;0�h;J
�xy�Xyv��:�aT$M�mw�qMoWz����c�AJ�A�ZZ댬��`�#������y8V2$�@	~�N�������e���в<Qt]�d��}�J��.܋�ˬ!����]�-��<�1���+��aTh��C8����#��/�F���ף�_O���n+������r�CFS	*���Z��wx���dX����D(t;r�Cj�( �7�@�/z\Έ�|�����ؤ�����tq�� }�;'�O�7�����2������A8���N{���Ϭ�E�?�nWyE�^��ӫ�V1';:q��]/��Ԏ����X}YD]�!A'���h\�#Am@���ߏ���� m� ���,��(�P���� ���]��� ��ivq��ΰ�yc��A�bNu �/�Źt�FP�*����.�>r�<��95\ �_���j[5�Z���p6i<	~��%>
:���.��9YA������`c����}ځ��U4^e8S'�!��+������Ƴ@t�H�V0�>����z����2����dՉ�m��Ɏ�1���34Ǳ��5�F;^evU'��KC�����P������C�Љm�S�d\x�EǓ�J �0?Q�-u,i'��ȪQ��+"�E���r�r년��+&~�l��&���S����L�Vw4�6$�G�Wk� ����T���%?K@�y~U�@2�:��ܱ~Q��m�t��K| D��M��i�� ��F]���,�xB���ЧX<	�C�k���8
lؼ�p�#��>�_����"�ˮ�]�k�9�� 
A�ْ��A�>�]l4���O��Ε���Ad���z9�ƶ�<A�~GQ8���p��q�Htp��޾�(cC=�T;�a��������c��}ܗ�}Ɇ�:M�-�,v�ޖ{�	O�m����S��s�a�W �':�c�OSRA����Em*��,��r$����A
��`|w}|=��D�� g@���ֱ�Q�yP���1�i���]XՎ���
���z��4wjsAȘ�5�i������YfaX�lϕ�|��&�<܏Lo��@�+UҬaɫ.�:�t%�&����cѠ��{����زѽ����/H��-�o�z��Ÿ۪�F�}�E�D��b_}k��u�.��o��	!q"x���)��_��d���갦ꐮa�`�~	j �Ǭ�+{�WQ6'r' ��'0��pd��&n[b'"O18�$�ň���_�sL#��#p����Д�������-F�up�����a�&}Gn�[�/\8n��ۏ*�|�s?���C~�kG���?�k.���n|�����6���OF����d(�������C����A 	�-�*�sÖ�0���5��̾��u�f�|�,N����P�h�;�shrG�W�pE�[�����Y��J��g	>s��W����� ��O���r���#�,�C$�$$�IFb�"�!%D�)��j)m\��qI"�!��!7��v����"�t��mAԞ�r�ca���9�|,��|�
~����>��<C�1C�=��M�]g_YܬJ<&5)Rj6�X8�EdI�	%�¤�$I�),JE��ԔA	)d�d4��#
.Q�bML�Iӎ�s����83�n(��z��x�ܒГ��Y'<ٙ}On[w�v�ߑ�
��c�B��Y�hQu��rE:s��%3\��<���sq6�$rY�e�\����van�o�/	��ʱ��Q�Yw��{r���K�3B)ϳ�|�cW�����0���Y<WU }o���dp:�����s5T��Ўjt�MHK�k�δ��������qaۤ�M��t�e�ᱝ&
�A�`�[ݜ!���$����Ô�I~+����9@�I>�<�s\q����x�����i��1��z֊p�e�|�ϊϦCu~��(�g�Τ	:����OX4~fQ䥧G��.�]0��hi�ol.~jM�Jb<�M�ɳ,'Vs�S��3�����v�]c�@r;��Ԯ=O��m���e���ʖDZ��,-�]��A�S��$<W��X���;An�T2�P���xz<y���3��-i�r�����c1�GD'�4uw����g��nb����|�v���b�����X������Σ6�C@�Ա[[;�.7�B��Xq@+"�!�X�\�XMl��Ё���@�o�u�����Ł����	�X��e��ͣ;ڸ���,�8��>�_�-}������H���o������#�|�74�%�&l�!�!�c�o!���A��%�
���M�OF�����/�^�Iྦྷ�+��%�/��������?��K:x�9x�9x�y�ho�^	�����`��%���S�d��
�ڑ��[�#�cr�"[�,�b�(�R�(m�Z!2jF�Q���
&�֙����^���·��C���$���&���?��qM�p���i�9���s4%4���\(_ו��2�$7���@��j��>���T}F�!��Z���j����z[*�FHZ��~�tRJ�{�N�8�j�x%�ŔYMR����؋c����/?�
��p����r��<��i����:���#�
��v����i_��l�}�+��� ��_�o�����A��#ݳ�H�����t:�����w��G����^�+ ��U\ :��?��A�߻�'�m�O��>ҫ%����(���}����a�ڒ�D���������ػ��DѮ{ϯx�]�e.޵>&n��$�����?MbUw�;�T���W)+����}�9g?pT�z��P��=�����RP��P�W�������Sw���%�F�����?�����[
ު��k����J]�?gY��_u�NHe;��?�J�?}MHn���u������c���>��y]�D>������Y%D>}l����,����.�YC)��YX����kf�C�sk;M3+��\��t���=��w���Xzȼh����m�c����������m����϶�_m�L�:�^>X��ݮ�K�󄤏�2Iν�f9��[�o�>��n�\ً�0u�H�#'�]QE#��������4-��!��d���Ǧ����S�����r�*ihɈ1��Qf67Ӡ�������iA,�j ��������W�z�?�D��Z���p8��@��?A��?U[�?�8�2P�����W�������?�7������?�&(�?u��a��:�9�o]��{�o�p�O����U�X��N�߸���~u����)�sg<:k�ߗ��[����c�LC�z�I�V�x6WZ����v�VLw�k�=�K+N��kFm�dO�(�Ă��Ͷ3�gd*����fH�&gOe=�׺>�5>���� Q��\}.��h�J���������m㛗84�9��1�)pD%8�:.�K߄Rn��6ev�Nz���m��c�o�:?��&)#�r�D�5�Yg�g�⒑6Z�S�0�E-��@�a���@��2<g�dB�_�������O�z/<�A��ԉ����1������b)�d)��8/DC�c=��Y�'h¥'<%|ڧ����3~u��G��P���_���=G]�b!4[M�F�$c���;�k�kǼ�hi�m�ŗ��ess$��'�#��d�>���62����rrG���B��#EY$ǒd���&��6#*j���Iq����u��C�gu����_A׷R����_u����Oe��?��?.e`�/�D����+뿃n��A���8b"98�ͧm/{;��,g�Sf�%�[�'��/��hЌW?gt�K�n�%����f���!�e���Џ�d���y��١a��uN�?2��d��
�����ߊP�������~���߀:���Wu��/����/����_��h�*P��0w���A������S\�_D��D�-�nxXO��I��X>M����E%�����[�a�\���g� @���3 �?�هg \������P�"�C �<�7����*�l��	��_�Kg7C�VSP���km�)�b��H�z�:���Pz����x�9�ތ݂����"r��まG/O����|�� ��rM��;!�[�E|"���q��4�h���H�<+��n(k$RXV��	��餭f�=o �\bk#����?�Ը���o�?i��5�y����lp��ИNՎ�ә��6HB϶��f�~���E�5C3�[g����~�hr��jc6�N��5���U�3�ދu��@���������}&<�2��[�?�~��b(��(u�}�����RP
�C�_mQ��`����/������������j�0�����?�s=�r=�CIe7���Q�s]��I.dP�fC����i.��˅$b.톰��i�C��h���O)���N�;,%���z�X8B�>��I�sr�oGdA��T�2�k%o�F��l��В��v�ö��٬	����|7飸<7���yD��M�G���CG�m��w"G:-k�G�u�ߋ:��1���?�������k�C���w(�����	��2P������+	���c�x�#��������U����P:���/���5AY������_x3�������������s���d�ĉ�\w��~Q���Ļ��o�����~_C~f����F�q�;���x�w���S-8ț�����k/O����ޑ�'�T/�=-͑���
�Mo91��=��*�����cJc�Is��MFɴ`0�R>��\]X���x��\{��s����v"����z�FP�{�\]oӵ�����P�Ek1ޥ:��#^�mQ1D2S�h�YӐd݂��\s�q��P�����;�A3R"�R�d�w�A�J�ԕ�\㘃�LFZg��Y$9������Xvi�����=8��"����|����������8F@�kE(��a�n�C��`��& ����7���7�C������*�����k�:�?���C����%� uA-����	���_����_������`��W>��Ȯ?���	x�2��G���RP��Q���'���@Y��x�nU���z���B������r�����/5���������?�����(���(e����?���P
 �� ��_=��S������_��(	5��R!�������O�� ����?��T�:����H�(�� ��� ����W���p�
��������W�z�?�C��Z���H�(�� ��� ������?���,�`��*@����_-�����W����KA����KG����0���0���.�
�������+5����]����k�:�?�� �?��:�?�]Ġ����P�a	���\8�I��9'�I�l�>A������y㺜K������/����A�_�T����R�G�����ݹT��?U�B�ݫ7`�*y�'�I���G#N��&6	��x�:�ZR�C�������E��bf��0��e�rE�Q�ȵ�J^!�hi��!u�Z���G�G�|����`��w}�)هsO�Xh�m�h�����IU���u��C�gu����_A׷R����_u����Oe��?��?.e`�/�D����+뿁Ohԩ��[y��QSd���B��Ű}��-lpڟ�T޸/��.���\�E��7,|��+A�:H�l2G���J��SK�6��A�v�v1���6�l5i�'��(�*i�Y�2�C��^���w�;��%�����������u������ �_���_����j�ЀU����a�����|����O��o�O�&#B�;zcN�lqd��(~s���~��{�vWi'	�റ�[>ց�{2���g�7�q�mi��LS/B;����J'����v/��0#Ǫ?�����b�mgD����)Y�þ���Nr�^ۍ��W����t�����a��\.�-�������,��]�ӌ�A���#A�X��ﺡP�#�e}�'�~�����/��&��aN���$m~�1o2����<����wrf���5ڽ���'�m���(X-W�F��x��	�[bٜmR����}w~���]�^�^�������R�����?~�������:�� ���K�g���`ī�(���8��(� ���:�?�b��_�����Ϲ���Q?����������H���+o��%�|p�����ǵ�n&1s�0N�s���:p�'�����ě���,M����&]~ԭW�B>z��Ο,?��~�,?��g�r�������KW��u9�Z�W��Z��9�dl��/N�"|w]5AȯufwC��WŴ��+s #J]��2����2�Ō��q����rѰR�]�9՛���a:���d4o��=c�-�c����[�쓕�侹�[;wu���M��׼�n������!���ħ�D EF,�c��֖h�vS�n��MnD�c�cP�E��|i�,]R�X�\�H�� ��{��
XDv)�;0*�y��'�4��k�\�T�%f#R"!������)zp�^�	�io�#7%ru��sf_Z��������������oI(G�1�z4F�3c1w��c��a���J�(N�f>C��%��)=sC�����,ԡ������?��+�r�_���q�e{+Ed'�MG�`�.a���J�����{��g��|D�\�
�����������P	�_�����^���W
J����Wc�q�������?�_)x���W�����){�ط�X�.3�	��;�ϵ������2P'�ԓ�w5ؐ�y�o�~��xW�y��7�����o����C���D�7;�P`�s�E�ې�A�ZG��Q�5��ר�M;�x��X��4/�����v�?9$���q1Y��Q������C>���l?���zr���ż=k7�Q�a�n;��Jt:KӖ��Ǽ2]��<���x���I�ì��^�0�
'���/%J�R^���K;���S5��J�̐fXs.l�9�
�q�+�.��me6wg��/��:�?����������K���,��Č��k�ϧ/_QL�<�r1�uY��7�E,F�.�Q�G0�#���D�q���#�>���>���ku�u��B�E����BN�<Wj�D�*�}_�-������{�rU-�Ge���g��������A�]�޽�CA���2>��u�Nx�%���������%��s��j�����?�]���P�����?�5���v��1�6�^ڡד�^?���}�C���lMPn����>�
~t;�QZ��[��A$�ɒ	M����|֥�Y_%�ǔ�Ǥo�壅ܻu�����n�+����?}��i���w�Ojb�������:uny�y�CO��*@E�}��u+���N��~��N:љtf�l&�OU�v�[���^k�am��׻���^��:'�xZΣ��:���֝�=����5�U���7[Da5v�C��j�
���3�ŽͬL����*�-9�rE�Zןn[�f5�R���B|^��z^�Qj
B�8��,E�+�`�7�&����ص�ao��]�/�[R�����p��lIV�����{]e!4�]Ø�:�<�j}��~U��{��o���Y�z���ve���l����Ty�2�cU���RI��R��J��g.��Ƀ�G][��2!�������+��߶������Б��C h�ȅ���!�; ��?!��?a�쿷��s�a �����_���ё��C!�������[��0��	P��A�7������{������~�,�������lȅ���ߡ�gFd��a��#�����%��3���エ� ��G��4u��?eJ������G��̕�_(��,ȉ�C]Dd���W��!��C6@��� �n�\���_�����$����۶�r��ŋ���y��AG.������C��L��P��?@����/k��B���۶�r��0�����?ԅ@D.��������&@��� ������+�`�'P��cC�?b���m�/��\�� �_�����T�����d@�?��C������`�(���y#/0��G���m��A��ԅ��?dD.���h�2I���Y�(34��u�L��ais�XbM�/���p�e�e-��2&Y&�"Gr���nݟ�<�����!�?^����2J�"�Q�>��r]��BSl��q+��L9�]����q�.�d��cݮ�q��ɝ�E���j-Nc�~���Z�vĆ?��=�nJ���NW���n��Q�tA�K!1��C��F+�%�s�!���T��f��۱kՈ�\Q��ŉ�o}�.I�Qi��Y�U糿wqQ�<g������@��Gk���y����CG��ЁR��x����[�vɃ���������ݤ�]�ס��D$��o�a�e��i[�wQm����g��Q���V{���F���mm��&�K;,�p�_K��vǷ�E��6��\���<F�j�]�cW��+9��)�N����k�G�_��_D�����~�F����/��B�A��A������h�l@����c��/��_|��ߣ���l��[v������U9rU���Og�զ?���|��&�d��W�Wv�8�z�{9�&�� 6�޸˒$��Ϣ�nQ�{cM�ۺ;)�%�>�+�|HZs�T��rb�y�ɦ� ��m���_ԺڮR
���VK�"n�s������WYü�0������k�Ѯ�ĮQyLS�������"<ڂ�s�'F_���ܬ���_i�4��6���|5��
�p:��m�RTW6jͽU�5�]�a��L��� ��RT�0�V:�0�����o���1��;p\�6dRk���k��6�K�`�Q,�B�[��O;@�GN������y%��,B�G�B��+�_<�d��O/^���>=�������&/��gA�� ���I`�����G��ԕ������bp�mq�����#��J���fB���@fOV����S��?�����������2��_& ��`H�����_.��@Fn��DB.��2�����L�f��)���>�(Qi������V��M��e\�h�l�?���}�����܏4��c����܏�ð?����~`����4��s�o�9��yx{]�o��D�zW<Q�:��$N-T��Y[v�2�a��Ƽ��Z����z�ِ���X� mt�}9�3FK��4��T�Q|u���b4��9����������v��%�Q��#M���b��i��-Ƃ2]��v=�Wp&�qՙ�:5X7�E�	Ϭ&mI��$��p���H����k���"�k.��Y��݇��T�P��>~����\�0����ߋE�Q��-��m�����GF����%�dJ.��+��(�����������B��30������E�Q7�M��m�����GD����0 �������d|���T�������k��0p\�4R[��9�T��5����Ǳl?O��Ʀ�66��s���� `O�|�(��m��?L�mh��QR*�Ap�������7mڢ7K�/�͐��h�Q���E�8Z�Q;ԋ\��J}cYVȇ��9 X��gr �4	��r z���7օE��]J��h9_�2��|ˏB������ړe�+)"�7-�?T�I9��ה�� qH�:�tkBu[��pz7������������ߧE�Q��m��m�y��"u��c�?��L����[�Z����"��K��S,m�4Y*�,eX�Ɠ����sf���s������3�����'��gÏ\�s����ø%�a:��6��Ӏji�r�뇓Y��Z��9�ʅ��?���7����.~�U��n�'"�٫��W�/|��i��~�r��C��aG���\=��ubO��\� ;�M`��ג����i��.��n�<�����#��?�@��O� &n ꦸI������G��x�/�5�#�"1'�
�b��Rl���CTk��)ዱu���ח��v8�Ҿ�W����eքS�1��ѱ_��8��:= �ǖ{�_5�����S=���B���ס59���k�G������Y���74X !�����/d@��A�����(��DC�?�-����o�����������𹱻�X] ��h�%݋�����#��?��=/�2���Ý��r�VӺ����j�a�\�4�X-j�ܢ󩌭��������q�I0Xl�m�PZ'V{h~��u�4+��mq�����K3K�<Q�z����Ui�SQ��B��	����ĸ)}�/�]K0)�NΟ���T��h����"�āl[^1
'�ʻ�HƘz~sO����ArӬfum8없�T�ڶ�l/b_i*��J�zj�l��!�#��.�%��CḶgǖ5��X������Xc�
�r�����x_m�hu�7�3�;N�U��ɿ����������w�z~^�gC�I&�����Iw�πswn�.��3-2���������Q�$�z� �k��S��RM����;�
v�/:�����r�&.=�9��� ':!~��"�k�X����;���^O7��������PR`&�������A���;~�T���O���Ƽ��O������>\|�g|c��ⸯ�?h�O�?��{��_����^=8�a��A�����q#\[��'f������3��{*fd���1r�W��Ą�T�🝫m9��'=�h:-L����o���^p�*J�û����9��H6<����_D�_��o{R������������y�*9*���_�����ӎ�?�}�?>OT$��6�κܟ�r���f��-v�av>~7O�>֒v�� �}3X�s����G��t%�9��%���sӇx�H�/ع����:����w�O�	Ý�)����|(�j{8�������6��f�˵}�µi���59������'�<_sr������^`S/���??��C�y����$K&��0��M��A,>7��3\��dU�q딒q�_\�]r�I�^�c�Z�}l�;R�US��N��$��]���y�¯?)��ݫf������?u��}~O���d                           \����� � 