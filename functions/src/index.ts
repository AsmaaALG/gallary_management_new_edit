const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const dayjs = require('dayjs');

exports.convertAdsToGalleries = functions.pubsub
.schedule('every day 00:00') // يشغّل يوميًا الساعة 00:00
  .onRun(async () => {
    const now = dayjs();

    const adsSnapshot = await db.collection('ads').get();

    for (const doc of adsSnapshot.docs) {
      const ad = doc.data();
      const adId = doc.id;

      try {
        const startDate = dayjs(ad['start date'], 'DD-MM-YYYY');
        const stopDate = dayjs(ad['stopAd'], 'DD-MM-YYYY');

        //  تحويل الإعلان إلى معرض
        if (!now.isBefore(startDate)) {
          const existingGallery = await db.collection('2')
            .where('ad_id', '==', adId)
            .limit(1)
            .get();

          if (existingGallery.empty) {
            const galleryDoc = await db.collection('2').add({
              title: ad.title,
              description: ad.description,
              'image url': ad['image url'],
              location: ad.location,
              'start date': ad['start date'],
              'end date': ad['end date'],
              'QR code': ad['qr code'] ?? '',
              'classification id': ad['classification id'],
              'company_id': ad['company_id'],
              map: ad.map,
              city: ad.city,
              ad_id: adId,
            });

            console.log(` تم تحويل الإعلان ${adId} إلى معرض.`);

            //  تحويل الطلبات المقبولة إلى أجنحة
            const acceptedForms = await db.collection('space_form')
              .where('adId', '==', adId)
              .where('accepted', '==', true)
              .get();

            for (const formDoc of acceptedForms.docs) {
              const form = formDoc.data();
              const selectedSuite = form.selectedSuite || {};

              await db.collection('suite').add({
                name: form.wingName || 'جناح بدون اسم',
                description: form.description || '',
                price: parseInt(selectedSuite.price || '0'),
                size: parseInt(selectedSuite.area || '0'),
                'title on map': selectedSuite.name || '',
                'gallery id': galleryDoc.id,
              });

              await formDoc.ref.delete();

              console.log(` تم تحويل الطلب ${formDoc.id} إلى جناح وحذفه`);
            }
          } else {
            console.log(` الإعلان ${adId} تم تحويله سابقًا.`);
          }
        }

        //  حذف الإعلان عند الوصول إلى تاريخ stopAd
        if (!now.isBefore(stopDate)) {
          await doc.ref.delete();
          console.log(` تم حذف الإعلان ${adId}`);

          const notifSnapshot = await db.collection('notifications')
            .where('ad_id', '==', adId)
            .get();

          for (const notifDoc of notifSnapshot.docs) {
            await notifDoc.ref.delete();
          }

          const formSnapshot = await db.collection('space_form')
            .where('adId', '==', adId)
            .get();

          for (const formDoc of formSnapshot.docs) {
            await formDoc.ref.delete();
          }

          console.log(` تم حذف الإشعارات والطلبات المرتبطة بـ ${adId}`);
        }
      } catch (e) {
        console.error(` خطأ في الإعلان ${adId}:`, e);
      }
    }

    return null;
  });
